class BlogController < ApplicationController
  BLOG_PATH = Rails.root.join('app', 'content', 'blog')

  TAG_LABELS = {
    "canal-plus"        => "Canal+",
    "bein-sports"       => "beIN Sports",
    "dazn"              => "DAZN",
    "droits-tv"         => "Droits TV",
    "champions-league"  => "Champions League",
    "europa-league"     => "Europa League",
    "conference-league" => "Conference League",
    "ligue-1"           => "Ligue 1",
    "premier-league"    => "Premier League",
    "liga"              => "La Liga",
    "bundesliga"        => "Bundesliga",
    "serie-a"           => "Serie A",
    "coupe-du-monde"    => "Coupe du Monde",
    "abonnement"        => "Abonnement",
    "streaming"         => "Streaming",
    "chaines-tv"        => "Chaînes TV",
    "d1-feminine"       => "D1 Féminine",
    "ligue-2"           => "Ligue 2"
  }.freeze

  PER_PAGE = 10

  def index
    all = all_articles
    @total_pages   = [(all.length.to_f / PER_PAGE).ceil, 1].max
    @current_page  = [[params[:page].to_i, 1].max, @total_pages].min
    @articles      = all.slice((@current_page - 1) * PER_PAGE, PER_PAGE) || []

    @page_title = @current_page > 1 \
      ? "Blog football — Page #{@current_page} | Coup d'Envoi TV" \
      : "Blog football — Guides et analyses | Coup d'Envoi TV"
    @page_desc  = "Guides pratiques, comparatifs d'abonnements et analyses football rédigés par Adrien pour ne rater aucun match en 2026."
    expires_in 1.hour, private: true
  end

  def auteur
    @articles = all_articles
    @page_title = "Adrien - Auteur football | Coup d'Envoi TV"
    @page_desc  = "Adrien, passionné de foot et fondateur de Coup d'Envoi TV. Guides pratiques, analyses, programmes TV et droits diffusion du football français et européen."
    expires_in 1.hour, private: true
  end

  def tag
    @tag      = params[:tag].to_s.downcase.strip
    @articles = all_articles.select { |a| a[:tags].include?(@tag) }
    render "errors/not_found", status: :not_found and return if @articles.empty?
    tag_label = TAG_LABELS[@tag] || @tag.gsub('-', ' ').split.map(&:capitalize).join(' ')
    @page_title = "Articles #{tag_label} — Blog | Coup d'Envoi TV"
    @page_desc  = "Tous les articles sur #{tag_label} : guides pratiques, droits TV et analyses rédigés par Adrien."
    @noindex = true
    expires_in 1.hour, private: true
  end

  def feed
    @articles = all_articles.first(20)
    @site_url = 'https://www.coupdenvoi.tv'
    render template: 'blog/feed', formats: [:xml], layout: false,
           content_type: 'application/rss+xml; charset=utf-8'
  end

  def show
    @article = load_article(params[:slug])
    render "errors/not_found", status: :not_found and return unless @article
    @page_title  = @article[:title]
    @page_desc   = @article[:meta_description]
    @article_html, @toc = render_markdown_with_toc(@article[:body])
    @article_html = inject_cdm_groups(@article_html) if @article_html.include?('[[groupe:')
    @article_html = inject_dazn_card(@article_html)  if @article_html.include?('DAZN_CARD')
    @article_html = inject_m6_dynamic(@article_html) if @article_html.include?('M6_GROUP_TABLE') || @article_html.include?('M6_KNOCKOUT_TABLE') || @article_html.include?('__TODAY__')

    @derby_matches = []
    if @article[:derby_pairs].present?
      @derby_matches = @article[:derby_pairs].filter_map do |pair|
        team_a, team_b = pair
        Match.where(
          "(home_team ILIKE :a AND away_team ILIKE :b) OR (home_team ILIKE :b AND away_team ILIKE :a)",
          a: "%#{team_a}%", b: "%#{team_b}%"
        ).where("start_time >= ?", Time.current - 3.hours)
         .order(:start_time)
         .first
      end
    end

    @match_groups = []
    if @article[:match_groups].present?
      @match_groups = @article[:match_groups].filter_map do |group_name, pairs|
        matches = (pairs || []).filter_map do |pair|
          team_a, team_b = pair
          Match.where(
            "(home_team ILIKE :a AND away_team ILIKE :b) OR (home_team ILIKE :b AND away_team ILIKE :a)",
            a: "%#{team_a}%", b: "%#{team_b}%"
          ).where("start_time >= ?", Time.current - 3.hours)
           .order(:start_time)
           .first
        end
        matches.any? ? { name: group_name, matches: matches } : nil
      end
    end

    @related_articles = related_articles_for(@article)

    # Card match (articles type "France - Sénégal : chaîne TV...")
    @blog_match = nil
    if @article[:match_card].is_a?(Hash)
      home = @article[:match_card]['home'].to_s.strip
      away = @article[:match_card]['away'].to_s.strip
      if home.present? && away.present?
        @blog_match = Match.where(
          "(home_team ILIKE :h AND away_team ILIKE :a) OR (home_team ILIKE :a AND away_team ILIKE :h)",
          h: "%#{home}%", a: "%#{away}%"
        ).order(:start_time).last
      end
    end

    # Programme dynamique d'un club (articles type "match psg ce soir chaîne")
    if @article[:club_schedule].is_a?(Hash)
      search = @article[:club_schedule]['search'].to_s.strip
      if search.present?
        @club_matches = Match.where(
          "home_team ILIKE :q OR away_team ILIKE :q", q: "%#{search}%"
        ).where("start_time >= ?", Time.current - 2.hours)
         .where.not(status: Match::FINISHED_STATUSES)
         .order(:start_time)
      end
    end

    # Matchs CdM 2026 dynamiques (articles type "match ce soir")
    if @article[:cdm_tonight]
      today_zone = Time.current.in_time_zone('Europe/Paris').to_date
      today_start = today_zone.beginning_of_day
      today_end   = today_zone.end_of_day

      @cdm_today_matches = Match.where(competition: "Coupe du Monde 2026")
                                .where(start_time: today_start..today_end)
                                .order(:start_time)

      @cdm_tournament_over = today_zone > Date.new(2026, 7, 19)

      if @cdm_today_matches.empty? && !@cdm_tournament_over
        next_match = Match.where(competition: "Coupe du Monde 2026")
                         .where("start_time > ?", today_end)
                         .where.not(status: Match::FINISHED_STATUSES)
                         .order(:start_time)
                         .first
        if next_match
          @cdm_next_match_date = next_match.start_time.in_time_zone('Europe/Paris').to_date
          next_day_end = @cdm_next_match_date.end_of_day
          @cdm_next_matches = Match.where(competition: "Coupe du Monde 2026")
                                   .where(start_time: @cdm_next_match_date.beginning_of_day..next_day_end)
                                   .order(:start_time)
        end
      end

      # Prochains jours (4 jours après aujourd'hui, excluant les matchs déjà montrés)
      upcoming_start = (today_zone + 1.day).beginning_of_day
      upcoming_end   = (today_zone + 5.days).end_of_day
      upcoming = Match.where(competition: "Coupe du Monde 2026")
                      .where(start_time: upcoming_start..upcoming_end)
                      .order(:start_time)
      @cdm_upcoming_by_date = upcoming.group_by { |m| m.start_time.in_time_zone('Europe/Paris').to_date }
    end

    # Prochain match France CdM 2026 (articles type "prochain match France")
    if @article[:france_next_match]
      now_paris = Time.current.in_time_zone('Europe/Paris')
      today_zone = now_paris.to_date
      france_scope = Match.where(competition: "Coupe du Monde 2026")
                          .where("home_team ILIKE '%France%' OR away_team ILIKE '%France%'")

      @france_tournament_over = today_zone > Date.new(2026, 7, 19)
      @france_eliminated = ENV['FRANCE_ELIMINATED'] == 'true'

      # Matchs passés (pour le récap parcours)
      @france_past_matches = france_scope.where(status: Match::FINISHED_STATUSES)
                                         .order(:start_time)

      # Prochain match (non terminé)
      @france_match = france_scope.where.not(status: Match::FINISHED_STATUSES)
                                  .order(:start_time)
                                  .first

      if @france_match
        match_date = @france_match.start_time.in_time_zone('Europe/Paris').to_date
        @france_today = match_date == today_zone
        @france_live  = @france_match.live?
        @france_days_until = (match_date - today_zone).to_i
      end
    end

    # Matchs CdM 2026 de demain (articles type "match demain")
    if @article[:cdm_tomorrow]
      today_zone = Time.current.in_time_zone('Europe/Paris').to_date
      tomorrow = today_zone + 1.day
      @cdm_tomorrow_date = tomorrow

      @cdm_tournament_over_tomorrow = today_zone > Date.new(2026, 7, 19)

      @cdm_tomorrow_matches = Match.where(competition: "Coupe du Monde 2026")
                                   .where(start_time: tomorrow.beginning_of_day..tomorrow.end_of_day)
                                   .order(:start_time)

      # Match "à ne pas rater" : France > round avancé > premier par heure
      @cdm_tomorrow_highlight = @cdm_tomorrow_matches.detect { |m|
        m.home_team =~ /france/i || m.away_team =~ /france/i
      } || @cdm_tomorrow_matches.detect { |m|
        m.round.to_s.downcase.match?(/final|semi|quarter/)
      }

      if @cdm_tomorrow_matches.empty? && !@cdm_tournament_over_tomorrow
        next_match = Match.where(competition: "Coupe du Monde 2026")
                         .where("start_time > ?", tomorrow.end_of_day)
                         .where.not(status: Match::FINISHED_STATUSES)
                         .order(:start_time)
                         .first
        if next_match
          @cdm_tomorrow_next_date = next_match.start_time.in_time_zone('Europe/Paris').to_date
          @cdm_tomorrow_next_matches = Match.where(competition: "Coupe du Monde 2026")
                                            .where(start_time: @cdm_tomorrow_next_date.beginning_of_day..@cdm_tomorrow_next_date.end_of_day)
                                            .order(:start_time)
        end
      end
    end

    ttl = if @article[:france_next_match] || @article[:cdm_tonight] || @article[:cdm_tomorrow] then 30.minutes
          elsif @article[:club_schedule].present? then 15.minutes
          else 1.hour
          end
    expires_in ttl, private: true
  end

  private

  def all_articles
    Dir.glob(BLOG_PATH.join('*.md')).filter_map { |f| parse_file(f) }
       .select { |a| a[:published_at] && article_published?(a) }
       .sort_by { |a| a[:published_at] }.reverse
  end

  def load_article(slug)
    file = BLOG_PATH.join("#{slug}.md")
    return nil unless File.exist?(file)
    article = parse_file(file, with_body: true)
    return nil unless article
    return nil unless article_published?(article)
    article
  end

  # Combine published_at (date) + published_time ("09h23") pour comparer à Time.current
  def article_published?(article)
    return false unless article[:published_at]
    pub_date = article[:published_at]
    pub_time = article[:published_time].to_s
    if pub_time.match?(/\A\d{1,2}h\d{2}\z/)
      h, m = pub_time.split('h').map(&:to_i)
      pub_datetime = Time.zone.local(pub_date.year, pub_date.month, pub_date.day, h, m)
    else
      pub_datetime = pub_date.to_time
    end
    Time.current >= pub_datetime
  end

  def parse_file(path, with_body: false)
    raw = File.read(path)
    return nil unless raw.start_with?('---')
    parts = raw.split('---', 3)
    return nil if parts.length < 3
    meta = YAML.safe_load(parts[1], permitted_classes: [Date]) rescue {}
    body_text = parts[2].strip
    word_count = body_text.gsub(/[#*`\[\]()>-]/, '').split.length
    reading_time = [(word_count / 200.0).ceil, 1].max

    result = {
      title:            meta['title'],
      meta_description: meta['meta_description'],
      slug:             meta['slug'],
      published_at:     meta['published_at'],
      published_time:   meta['published_time'],
      updated_at:       meta['updated_at'],
      author:           meta['author'] || 'Adrien',
      image:            meta['image'],
      image_credit:     meta['image_credit'],
      excerpt:          meta['excerpt'],
      derby_pairs:       meta['derby_pairs'],
      match_pairs_title: meta['match_pairs_title'],
      match_groups:      meta['match_groups'],
      reading_time:      reading_time,
      dazn_card:         meta.key?('dazn_card') ? meta['dazn_card'] : true,
      canal_plus_card:   meta.key?('canal_plus_card') ? meta['canal_plus_card'] : true,
      tags:              Array(meta['tags']).map(&:to_s).reject(&:blank?),
      club_schedule:     meta['club_schedule'],
      match_card:        meta['match_card'],
      cdm_tonight:       meta['cdm_tonight'],
      france_next_match: meta['france_next_match'],
      cdm_tomorrow:      meta['cdm_tomorrow']
    }
    result[:body] = body_text if with_body
    result
  end

  def related_articles_for(article)
    others = all_articles.reject { |a| a[:slug] == article[:slug] }
    selected = []

    # Slot 1 — même tag, random
    if article[:tags].any?
      same_tag = others.select { |a| (a[:tags] & article[:tags]).any? }
      slot1 = same_tag.sample
      selected << slot1 if slot1
    end

    # Slot 2 — article affilié random (dazn_card ou canal_plus_card actif)
    affiliate = (others - selected).select { |a| a[:dazn_card] != false || a[:canal_plus_card] != false }
    slot2 = affiliate.sample
    selected << slot2 if slot2

    # Slot 3 — random global
    slot3 = (others - selected).sample
    selected << slot3 if slot3

    # Fallback : compléter avec les plus récents si pas assez
    if selected.length < 3
      recent = (others - selected).first(3 - selected.length)
      selected += recent
    end

    selected.first(3)
  end

  def inject_cdm_groups(html)
    cdm_groups = YAML.load_file(Rails.root.join('config', 'cdm_2026_groups.yml'))
    standing    = Standing.for_league(1)
    all_groups  = standing&.data&.dig(0, "league", "standings") || []

    result = html.gsub(/\[\[groupe:([A-La-l])\]\]/) do
      letter     = $1.upcase
      group_data = cdm_groups[letter]
      next '' unless group_data

      group_index = letter.ord - 'A'.ord
      rows        = all_groups[group_index] || []
      tournament_started = Date.today >= Date.new(2026, 6, 11)

      out = <<~HTML
        <div style="background: white; border-radius: 12px; overflow: hidden; border: 1px solid #e2e8f0; margin: 20px 0;">
          <div style="display: flex; align-items: center; justify-content: space-between; padding: 10px 14px; background: #f8fafc; border-bottom: 1px solid #e2e8f0;">
            <span style="font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em; color: #64748b;">#{group_data["label"]}</span>
            <a href='/competitions/coupe-du-monde-2026/groupe-#{letter.downcase}' style='font-size: 11px; color: var(--color-accent); font-weight: 700; text-decoration: none;'>Voir le groupe →</a>
          </div>
      HTML

      if rows.any?
        out += <<~HTML
          <div style="display: flex; align-items: center; padding: 6px 12px; background: #f8fafc; border-bottom: 1px solid #f1f5f9;">
            <span style="width: 20px; font-size: 10px; font-weight: 700; color: #94a3b8;">#</span>
            <span style="flex: 1; font-size: 10px; font-weight: 700; color: #94a3b8; margin-left: 30px;">Équipe</span>
            <span style="width: 22px; font-size: 10px; font-weight: 700; color: #94a3b8; text-align: center;">J</span>
            <span style="width: 22px; font-size: 10px; font-weight: 700; color: #94a3b8; text-align: center;">G</span>
            <span style="width: 22px; font-size: 10px; font-weight: 700; color: #94a3b8; text-align: center;">N</span>
            <span style="width: 22px; font-size: 10px; font-weight: 700; color: #94a3b8; text-align: center;">P</span>
            <span style="width: 30px; font-size: 10px; font-weight: 700; color: #94a3b8; text-align: center;">Pts</span>
          </div>
        HTML
        rows.each_with_index do |rank, idx|
          border_left = idx < 2 ? 'border-left: 3px solid var(--color-accent);' : 'border-left: 3px solid transparent;'
          border_bottom = idx < rows.size - 1 ? 'border-bottom: 1px solid #f1f5f9;' : ''
          logo = rank.dig('team', 'logo').to_s
          name = rank.dig('team', 'name').to_s
          out += <<~HTML
            <div style="display: flex; align-items: center; padding: 8px 12px; #{border_bottom} #{border_left}">
              <span style="width: 20px; font-size: 11px; font-weight: 700; color: #94a3b8;">#{rank["rank"]}</span>
              <img src='#{logo}' alt='#{name}' width='22' height='22' loading='lazy' style='width: 22px; height: 22px; object-fit: contain; margin-right: 8px; flex-shrink: 0;'>
              <span style="flex: 1; font-size: 13px; font-weight: 600; color: #010e1b; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">#{ApplicationController.helpers.team_display_name(name)}</span>
              <span style="width: 22px; font-size: 12px; color: #64748b; text-align: center;">#{rank.dig('all', 'played')}</span>
              <span style="width: 22px; font-size: 12px; color: #64748b; text-align: center;">#{rank.dig('all', 'win')}</span>
              <span style="width: 22px; font-size: 12px; color: #64748b; text-align: center;">#{rank.dig('all', 'draw')}</span>
              <span style="width: 22px; font-size: 12px; color: #64748b; text-align: center;">#{rank.dig('all', 'lose')}</span>
              <span style="width: 30px; font-size: 13px; font-weight: 900; color: #010e1b; text-align: center;">#{rank["points"]}</span>
            </div>
          HTML
        end
      else
        group_data["teams_fr"].each_with_index do |team, idx|
          border_bottom = idx < group_data["teams_fr"].size - 1 ? 'border-bottom: 1px solid #f1f5f9;' : ''
          out += "<div style='padding: 9px 14px; font-size: 13px; font-weight: 600; color: #010e1b; #{border_bottom}'>#{team}</div>\n"
        end
        unless tournament_started
          out += "<div style='padding: 8px 14px; font-size: 11px; color: #94a3b8; text-align: center; border-top: 1px solid #f1f5f9;'>Classement live dès le 11 juin 2026</div>\n"
        end
      end

      out += "</div>"
      out
    end
    result.html_safe
  end

  DAZN_AFFILIATE_URL = 'https://dazn.prf.hn/click/camref:1100l5JbRk'.freeze

  def inject_dazn_card(html)
    card = <<~HTML
      <div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:8px;padding:20px 24px;margin:28px 0;display:flex;align-items:center;justify-content:space-between;gap:16px;flex-wrap:wrap;">
        <div>
          <strong style="font-size:15px;color:#0f172a;">S'abonner à DAZN</strong>
          <p style="margin:4px 0 0;color:#64748b;font-size:13px;">Serie A, Liga, Bundesliga et Ligue 1+ à partir de 9,99 €/mois</p>
        </div>
        <a href="#{DAZN_AFFILIATE_URL}" target="_blank" rel="noopener sponsored" style="display:inline-flex;align-items:center;gap:6px;background:#0f172a;color:white;padding:10px 18px;border-radius:6px;font-size:14px;font-weight:600;text-decoration:none;white-space:nowrap;">Voir l'offre DAZN →</a>
      </div>
    HTML
    html.gsub(/<!--\s*DAZN_CARD\s*-->/, card).html_safe
  end

  MOLOTOV_URL = 'https://molotov.pxf.io/c/7376919/3924296/16522'.freeze

  def inject_m6_dynamic(html)
    cdm = Match.where(competition: 'Coupe du Monde 2026', tv_channels: 'M6')

    # Group stage table
    if html.include?('M6_GROUP_TABLE')
      group_matches = cdm.where("round ILIKE '%group%'").order(:start_time)
      table = build_m6_table(group_matches)
      html = html.gsub(/<!--\s*M6_GROUP_TABLE\s*-->/, table)
    end

    # Knockout table
    if html.include?('M6_KNOCKOUT_TABLE')
      knockout_matches = cdm.where("round NOT ILIKE '%group%'").order(:start_time)
      if knockout_matches.any?
        table = build_m6_table(knockout_matches, knockout: true)
      else
        table = '<p style="color:#64748b;font-style:italic;">Les matchs de phase finale seront affichés ici au fur et à mesure des qualifications.</p>'
      end
      html = html.gsub(/<!--\s*M6_KNOCKOUT_TABLE\s*-->/, table)
    end

    # dateModified auto-update
    html = html.gsub('__TODAY__', Date.today.iso8601)

    html.html_safe
  end

  def build_m6_table(matches, knockout: false)
    h = ApplicationController.helpers
    rows = matches.map do |m|
      paris_time = m.start_time.in_time_zone('Europe/Paris')
      date_str = I18n.l(paris_time, format: '%A %d %B', locale: :fr).sub(/^./, &:upcase)
      hour_str = paris_time.strftime('%Hh%M')
      home_fr = h.team_display_name(m.home_team)
      away_fr = h.team_display_name(m.away_team)

      # Score si terminé
      score = if m.status.in?(Match::FINISHED_STATUSES) && m.home_score.present?
                "#{m.home_score}-#{m.away_score}"
              else
                hour_str
              end

      # Round info pour knockout
      round_label = knockout ? (m.round.to_s.presence || '') : ''

      match_label = "#{home_fr} - #{away_fr}"
      slug = m.slug.presence
      match_cell = slug ? "<a href='/matchs/#{slug}' style='color:var(--color-accent);text-decoration:none;font-weight:600;'>#{match_label}</a>" : "<strong>#{match_label}</strong>"

      night = paris_time.hour < 6
      night_badge = night ? " <span style='display:inline-block;background:#fef3c7;color:#92400e;font-size:10px;font-weight:700;padding:1px 5px;border-radius:4px;margin-left:4px;'>NUIT</span>" : ""

      "<tr>
        <td style='padding:8px 10px;white-space:nowrap;font-size:13px;color:#64748b;border-bottom:1px solid #f1f5f9;'>#{date_str}</td>
        <td style='padding:8px 10px;font-size:13px;border-bottom:1px solid #f1f5f9;'>#{match_cell}#{' <span style="font-size:11px;color:#94a3b8;">(' + round_label + ')</span>' if round_label.present?}</td>
        <td style='padding:8px 10px;font-size:13px;font-weight:600;color:#0f172a;text-align:center;border-bottom:1px solid #f1f5f9;white-space:nowrap;'>#{score}#{night_badge}</td>
      </tr>"
    end.join("\n")

    count = matches.count
    <<~HTML
      <div style="overflow-x:auto;margin:20px 0;">
        <table style="width:100%;border-collapse:collapse;background:white;border:1px solid #e2e8f0;border-radius:8px;overflow:hidden;">
          <thead>
            <tr style="background:#f8fafc;">
              <th style="padding:10px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:0.05em;color:#64748b;text-align:left;border-bottom:1px solid #e2e8f0;">Date</th>
              <th style="padding:10px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:0.05em;color:#64748b;text-align:left;border-bottom:1px solid #e2e8f0;">Match</th>
              <th style="padding:10px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:0.05em;color:#64748b;text-align:center;border-bottom:1px solid #e2e8f0;">Heure / Score</th>
            </tr>
          </thead>
          <tbody>
            #{rows}
          </tbody>
        </table>
        <p style="font-size:12px;color:#94a3b8;margin-top:6px;text-align:right;">#{count} matchs M6 — mis à jour le #{I18n.l(Date.today, format: '%d %B %Y', locale: :fr)}</p>
      </div>
    HTML
  end

  def render_markdown_with_toc(text)
    renderer = Redcarpet::Render::HTML.new(hard_wrap: false)
    md = Redcarpet::Markdown.new(renderer, tables: true, no_intra_emphasis: true, autolink: false)
    html = md.render(text)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    toc = []
    doc.css('h2').each do |h2|
      heading_text = h2.text.strip
      anchor = heading_text.parameterize
      h2['id'] = anchor
      toc << { text: heading_text, anchor: anchor }
    end
    [doc.to_html.html_safe, toc]
  end
end
