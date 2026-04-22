require 'google/apis/searchconsole_v1'
require 'googleauth'

class GoogleSearchConsoleService
  SITE_URL   = ENV.fetch('GSC_SITE_URL', 'sc-domain:coupdenvoi.tv')
  ROW_LIMIT  = 25_000
  GSC_DELAY_DAYS = 3  # GSC data is ~3 days behind

  CHANNEL_SLUGS = %w[
    canal-plus bein-sports dazn amazon-prime rmc-sport france-tv tf1 m6
  ].freeze

  def initialize
    credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(ENV.fetch('GOOGLE_SERVICE_ACCOUNT_JSON')),
      scope: 'https://www.googleapis.com/auth/webmasters.readonly'
    )
    @service = Google::Apis::SearchconsoleV1::SearchConsoleService.new
    @service.authorization = credentials
  end

  def fetch_weekly_data
    today     = Date.today
    end_date  = today - GSC_DELAY_DAYS
    start_date = end_date - 6  # 7-day window

    prev_end   = start_date - 1
    prev_start = prev_end - 6

    yoy_end    = end_date - 364
    yoy_start  = start_date - 364

    puts "📅 Période courante : #{start_date} → #{end_date}"
    puts "📅 N-1              : #{prev_start} → #{prev_end}"
    puts "📅 N-52             : #{yoy_start} → #{yoy_end}"

    current_rows  = fetch_rows(start_date, end_date, dimensions: %w[page query])
    previous_rows = fetch_rows(prev_start, prev_end, dimensions: %w[page query])
    yoy_rows      = fetch_rows(yoy_start, yoy_end,   dimensions: %w[page query])

    {
      summary:           build_summary(current_rows, previous_rows, yoy_rows, start_date, end_date),
      pages:             build_pages(current_rows, previous_rows, yoy_rows),
      by_type:           build_by_type(current_rows),
      top_queries:       build_top_queries(current_rows),
      cannibalization:   detect_cannibalization(current_rows),
      football_context:  build_football_context,
      existing_pages:    build_existing_pages
    }
  end

  private

  # ── GSC API ──────────────────────────────────────────────────────────────

  def fetch_rows(start_date, end_date, dimensions:)
    request = Google::Apis::SearchconsoleV1::SearchAnalyticsQueryRequest.new(
      start_date: start_date.to_s,
      end_date:   end_date.to_s,
      dimensions: dimensions,
      row_limit:  ROW_LIMIT,
      data_state: 'final'
    )
    response = @service.query_search_analytics(SITE_URL, request)
    response.rows || []
  rescue Google::Apis::Error => e
    Rails.logger.error("GSC API error (#{start_date}→#{end_date}): #{e.message}")
    []
  end

  # ── SUMMARY ──────────────────────────────────────────────────────────────

  def build_summary(current, previous, yoy, start_date, end_date)
    {
      current:  aggregate_metrics(current, period: "#{start_date}/#{end_date}"),
      previous: aggregate_metrics(previous),
      year_ago: aggregate_metrics(yoy)
    }
  end

  def aggregate_metrics(rows, period: nil)
    return { clicks: 0, impressions: 0, ctr: 0.0, position: 0.0 } if rows.empty?

    total_clicks = rows.sum { |r| r.clicks.to_i }
    total_imp    = rows.sum { |r| r.impressions.to_i }
    # weighted avg position
    avg_pos = rows.sum { |r| r.position.to_f * r.impressions.to_i } / [total_imp, 1].max

    result = {
      clicks:      total_clicks,
      impressions: total_imp,
      ctr:         total_imp > 0 ? (total_clicks.to_f / total_imp * 100).round(2) : 0.0,
      position:    avg_pos.round(2)
    }
    result[:period] = period if period
    result
  end

  # ── PAGES ────────────────────────────────────────────────────────────────

  def build_pages(current, previous, yoy)
    # Aggregate by page
    current_by_page  = aggregate_by_page(current)
    previous_by_page = aggregate_by_page(previous)
    yoy_by_page      = aggregate_by_page(yoy)

    current_by_page
      .sort_by { |_, m| -m[:impressions] }
      .first(50)
      .map do |url, metrics|
        path = path_from_url(url)
        type = detect_page_type(path)

        prev = previous_by_page[url] || { position: nil }
        yoy_m = yoy_by_page[url] || { position: nil }

        delta_wow = metrics[:position] && prev[:position] ?
          (metrics[:position] - prev[:position]).round(2) : nil
        delta_yoy = metrics[:position] && yoy_m[:position] ?
          (metrics[:position] - yoy_m[:position]).round(2) : nil

        metrics.merge(
          url:               path,
          type:              type,
          delta_wow_position: delta_wow,
          delta_yoy_position: delta_yoy
        )
      end
  end

  def aggregate_by_page(rows)
    rows.each_with_object(Hash.new { |h, k| h[k] = { clicks: 0, impressions: 0, position_sum: 0.0 } }) do |row, acc|
      page = row.keys[0]  # first dimension = page when dimensions: [page, query]
      acc[page][:clicks]       += row.clicks.to_i
      acc[page][:impressions]  += row.impressions.to_i
      acc[page][:position_sum] += row.position.to_f * row.impressions.to_i
    end.transform_values do |m|
      imp = [m[:impressions], 1].max
      {
        clicks:      m[:clicks],
        impressions: m[:impressions],
        ctr:         (m[:clicks].to_f / imp * 100).round(2),
        position:    (m[:position_sum] / imp).round(2)
      }
    end
  end

  # ── BY TYPE ──────────────────────────────────────────────────────────────

  def build_by_type(rows)
    by_page = aggregate_by_page(rows)
    result  = Hash.new { |h, k| h[k] = { clicks: 0, impressions: 0, position_sum: 0.0, page_count: 0 } }

    by_page.each do |url, metrics|
      type = detect_page_type(path_from_url(url))
      result[type][:clicks]       += metrics[:clicks]
      result[type][:impressions]  += metrics[:impressions]
      result[type][:position_sum] += metrics[:position] * metrics[:impressions]
      result[type][:page_count]   += 1
    end

    result.transform_values do |m|
      imp = [m[:impressions], 1].max
      {
        clicks:      m[:clicks],
        impressions: m[:impressions],
        ctr:         (m[:clicks].to_f / imp * 100).round(2),
        position:    (m[:position_sum] / imp).round(2),
        page_count:  m[:page_count]
      }
    end
  end

  # ── TOP QUERIES ──────────────────────────────────────────────────────────

  def build_top_queries(rows)
    by_query = rows.each_with_object(Hash.new { |h, k| h[k] = { clicks: 0, impressions: 0, position_sum: 0.0 } }) do |row, acc|
      query = row.keys[1]  # second dimension = query
      next unless query
      acc[query][:clicks]       += row.clicks.to_i
      acc[query][:impressions]  += row.impressions.to_i
      acc[query][:position_sum] += row.position.to_f * row.impressions.to_i
    end

    by_query
      .select { |_, m| m[:impressions] > 50 || m[:clicks] > 0 }
      .map do |query, m|
        imp = [m[:impressions], 1].max
        {
          query:       query,
          clicks:      m[:clicks],
          impressions: m[:impressions],
          ctr:         (m[:clicks].to_f / imp * 100).round(2),
          position:    (m[:position_sum] / imp).round(2)
        }
      end
      .sort_by { |q| -q[:impressions] }
      .first(200)
  end

  # ── CANNIBALIZATION ──────────────────────────────────────────────────────

  def detect_cannibalization(rows)
    # Group rows by query, collect distinct pages
    by_query = rows.each_with_object(Hash.new { |h, k| h[k] = {} }) do |row, acc|
      query = row.keys[1]
      page  = row.keys[0]
      next unless query && page
      path = path_from_url(page)
      acc[query][path] ||= 0.0
      # track best position per page for this query
      acc[query][path] = [acc[query][path], row.position.to_f].min
    end

    by_query
      .select { |_, pages| pages.size >= 2 }
      .map do |query, pages|
        sorted = pages.sort_by { |_, pos| pos }
        {
          query:        query,
          pages:        sorted.map { |path, pos| { url: path, position: pos.round(2) } },
          top_position: sorted.first[1].round(2)
        }
      end
      .sort_by { |c| c[:top_position] }
      .first(30)
  end

  # ── FOOTBALL CONTEXT ─────────────────────────────────────────────────────

  def build_football_context
    today = Date.today
    in_3_weeks = today + 21

    # Active competitions (have upcoming matches)
    active = Match.where("start_time >= ?", Time.current)
                  .distinct.pluck(:competition).compact.sort

    # Competitions ending soon (last match within 21 days)
    ending_soon = Match.where("start_time BETWEEN ? AND ?", Time.current, in_3_weeks.end_of_day)
                       .group(:competition)
                       .maximum(:start_time)
                       .select { |_, last| last.to_date <= in_3_weeks }
                       .map do |comp, last_match|
                         "#{comp} — dernier match le #{last_match.strftime('%d/%m')}"
                       end

    # Upcoming highlights (next 14 days, TV matches)
    highlights = Match.where("start_time BETWEEN ? AND ?", Time.current, 14.days.from_now)
                      .where.not(tv_channels: [nil, ''])
                      .order(:start_time)
                      .limit(20)
                      .map do |m|
                         {
                           match:       "#{m.home_team} vs #{m.away_team}",
                           date:        m.start_time.strftime('%Y-%m-%d %H:%M'),
                           competition: m.competition,
                           tv:          m.tv_channels,
                           slug:        m.slug
                         }
                       end

    {
      active_competitions:  active,
      ending_soon:          ending_soon,
      upcoming_highlights:  highlights
    }
  end

  # ── EXISTING PAGES ───────────────────────────────────────────────────────

  def build_existing_pages
    pages = []

    # Static pages
    pages += %w[
      /
      /resultats
      /equipes
      /joueurs
      /competitions
      /classements
      /blog
      /blog/auteur/adrien
      /chaines
      /contact
      /a-propos
      /archives
      /nous-soutenir
    ]

    # Channel pages
    CHANNEL_SLUGS.each { |s| pages << "/chaines/#{s}" }

    # Competition pages (non-archived, from COMPETITIONS_META)
    FootballApiService::COMPETITIONS_META
      .reject { |c| c[:archived] }
      .each do |c|
        slug = c[:name].parameterize
        pages << "/competitions/#{slug}"
        if c[:has_standings]
          pages << "/classements/#{c[:id]}"
          pages << "/classements/#{c[:id]}/buteurs"
        end
      end

    # Team pages
    Match.distinct.pluck(:home_team, :away_team)
         .flatten.compact.uniq
         .each { |t| pages << "/equipes/#{t.parameterize}" }

    # Player pages
    Player.distinct.pluck(:slug)
          .each { |s| pages << "/joueurs/#{s}" }

    # Match pages (recent 30 days + upcoming 60 days)
    Match.where("start_time BETWEEN ? AND ?", 30.days.ago, 60.days.from_now)
         .where.not(slug: [nil, ''])
         .pluck(:slug)
         .each { |s| pages << "/matches/#{s}" }

    # Blog articles
    blog_path = Rails.root.join('app', 'content', 'blog')
    if Dir.exist?(blog_path)
      Dir.glob(blog_path.join('*.md')).each do |f|
        raw = File.read(f)
        next unless raw.start_with?('---')
        parts = raw.split('---', 3)
        next if parts.length < 3
        meta = YAML.safe_load(parts[1], permitted_classes: [Date]) rescue {}
        slug = meta['slug']
        published_at = meta['published_at']
        next unless slug && published_at && published_at <= Date.today
        pages << "/blog/#{slug}"
      end
    end

    pages.uniq.sort
  end

  # ── HELPERS ──────────────────────────────────────────────────────────────

  def path_from_url(url)
    uri = URI.parse(url)
    uri.path
  rescue URI::InvalidURIError
    url
  end

  def detect_page_type(path)
    case path
    when /\A\/matches\//                then 'match'
    when /\A\/competitions\//           then 'competition'
    when /\A\/equipes\//                then 'equipe'
    when /\A\/joueurs\//                then 'joueur'
    when /\A\/classements\//            then 'classement'
    when /\A\/chaines\//                then 'chaine'
    when /\A\/blog\//                   then 'blog'
    when /\A\/resultats/                then 'resultats'
    when /\A\/days\//                   then 'day'
    when /\A\/(equipes|joueurs|competitions|classements|chaines|blog)\z/ then 'index'
    when /\A\/\z/                       then 'home'
    else                                     'autre'
    end
  end
end
