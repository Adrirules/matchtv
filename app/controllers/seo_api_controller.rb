class SeoApiController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate!

  # GET /api/seo/fetch-data?period=weekly|monthly&token=...
  def fetch_data
    period = params[:period].presence&.strip == "monthly" ? "monthly" : "weekly"
    gsc    = GscService.new

    if period == "monthly"
      current_start  = Date.today.prev_month.beginning_of_month
      current_end    = Date.today.prev_month.end_of_month
      previous_start = (current_start - 1).beginning_of_month
      previous_end   = current_start - 1
      months_fr      = %w[janvier février mars avril mai juin juillet août septembre octobre novembre décembre]
      label          = "#{months_fr[current_start.month - 1]} #{current_start.year}"
    else
      wday           = Date.today.wday == 0 ? 7 : Date.today.wday
      current_start  = Date.today - wday + 1 - 7
      current_end    = current_start + 6
      previous_start = current_start - 7
      previous_end   = current_start - 1
      label          = "#{current_start.strftime('%d/%m')} au #{current_end.strftime('%d/%m/%Y')}"
    end

    year_ago_start = current_start - 365
    year_ago_end   = current_end   - 365

    current          = gsc.top_pages(start_date: current_start,  end_date: current_end,  limit: 50)
    previous         = gsc.top_pages(start_date: previous_start, end_date: previous_end, limit: 50)
    year_ago         = gsc.top_pages(start_date: year_ago_start,  end_date: year_ago_end,  limit: 50)
    summary_current  = gsc.summary(start_date: current_start,  end_date: current_end)
    summary_previous = gsc.summary(start_date: previous_start, end_date: previous_end)
    summary_year_ago = gsc.summary(start_date: year_ago_start,  end_date: year_ago_end)
    top_queries      = gsc.top_queries(start_date: current_start, end_date: current_end, limit: 200)
    queries_by_page  = gsc.queries_by_page(start_date: current_start, end_date: current_end, limit: 200)

    cannibalization = queries_by_page
      .group_by { |r| r[:query] }
      .select   { |_, rows| rows.size > 1 && rows.sum { |r| r[:impressions] } > 50 }
      .map { |q, rows| { query: q, pages: rows.map { |r| r.slice(:page, :type, :impressions, :position) } } }
      .sort_by  { |r| -r[:pages].sum { |p| p[:impressions] } }
      .first(20)

    prev_map     = previous.index_by { |r| r[:page] }
    year_ago_map = year_ago.index_by  { |r| r[:page] }
    pages_with_delta = current.map do |r|
      prev = prev_map[r[:page]]
      ya   = year_ago_map[r[:page]]
      r.merge(
        prev_position:   prev&.dig(:position),
        delta_pos_wow:   prev ? (r[:position] - prev[:position]).round(1) : nil,
        delta_pos_yoy:   ya   ? (r[:position] - ya[:position]).round(1)   : nil,
        impressions_yoy: ya&.dig(:impressions),
        is_new:          prev.nil?
      )
    end

    by_type = pages_with_delta.group_by { |r| r[:type] }.transform_values do |pages|
      {
        count: pages.size,
        impressions: pages.sum { |p| p[:impressions] },
        clicks:      pages.sum { |p| p[:clicks] },
        avg_ctr:     pages.any? ? (pages.sum { |p| p[:ctr] } / pages.size).round(1) : 0,
        avg_pos:     pages.any? ? (pages.sum { |p| p[:position] } / pages.size).round(1) : 0
      }
    end

    today = Date.today
    active_competitions = Match.where(start_time: today..(today + 30)).distinct.pluck(:competition).compact.uniq.first(12)
    ending_soon         = Match.where(start_time: today..(today + 14)).distinct.pluck(:competition).compact.uniq.first(8)
    recent_competitions = Match.where(start_time: (today - 14)..today).distinct.pluck(:competition).compact.uniq.first(10)
    next_big_matches    = Match.where(start_time: today..(today + 7))
                               .order(:start_time).limit(10)
                               .pluck(:home_team, :away_team, :competition, :start_time)
                               .map { |h, a, c, t| "#{h} vs #{a} (#{c}) le #{t.strftime('%d/%m')}" }

    existing_pages = {
      competitions: FootballApiService::COMPETITIONS_META.map { |c| c[:name] },
      blog_articles: Dir[Rails.root.join("app/content/blog/*.md")].map { |f| File.basename(f, ".md") }.sort,
      chaines: %w[canal-plus bein-sports dazn amazon-prime-video rmc-sport france-tv tf1 m6],
      top_teams: Match.where(start_time: (today - 90)..)
                      .flat_map { |m| [m.home_team, m.away_team] }.compact
                      .tally.sort_by { |_, n| -n }.first(30).map(&:first)
    }

    render json: {
      period: period, label: label, generated_at: today.strftime("%d/%m/%Y"),
      summary: { current: summary_current, previous: summary_previous, year_ago: summary_year_ago },
      pages: pages_with_delta, by_type: by_type,
      top_queries: top_queries, cannibalization: cannibalization,
      football_context: {
        today: today.strftime("%d/%m/%Y"),
        active_competitions: active_competitions, ending_soon: ending_soon,
        recent_competitions: recent_competitions, next_big_matches: next_big_matches
      },
      existing_pages: existing_pages
    }
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end

  # POST /api/seo/send-report
  # Body JSON : { period: "weekly"|"monthly", analysis: "..." }
  def send_report
    period   = params[:period].presence&.strip == "monthly" ? "monthly" : "weekly"
    analysis = params[:analysis].to_s.strip
    return render json: { error: "analysis manquant" }, status: :bad_request if analysis.blank?

    gsc = GscService.new

    if period == "monthly"
      current_start  = Date.today.prev_month.beginning_of_month
      current_end    = Date.today.prev_month.end_of_month
      previous_start = (current_start - 1).beginning_of_month
      previous_end   = current_start - 1
      months_fr      = %w[janvier février mars avril mai juin juillet août septembre octobre novembre décembre]
      month_label    = "#{months_fr[current_start.month - 1]} #{current_start.year}"

      current          = gsc.top_pages(start_date: current_start,  end_date: current_end,  limit: 30)
      previous         = gsc.top_pages(start_date: previous_start, end_date: previous_end, limit: 30)
      summary_current  = gsc.summary(start_date: current_start,  end_date: current_end)
      summary_previous = gsc.summary(start_date: previous_start, end_date: previous_end)

      SeoReportMailer.monthly_report(
        current: current, previous: previous,
        summary_current: summary_current, summary_previous: summary_previous,
        analysis: analysis, month_label: month_label
      ).deliver_now
    else
      wday          = Date.today.wday == 0 ? 7 : Date.today.wday
      current_start = Date.today - wday + 1 - 7
      current_end   = current_start + 6
      prev_start    = current_start - 7
      prev_end      = current_start - 1
      week_label    = "#{current_start.strftime('%d/%m')} au #{current_end.strftime('%d/%m/%Y')}"

      current          = gsc.top_pages(start_date: current_start, end_date: current_end,  limit: 25)
      previous         = gsc.top_pages(start_date: prev_start,    end_date: prev_end,     limit: 25)
      summary_current  = gsc.summary(start_date: current_start, end_date: current_end)
      summary_previous = gsc.summary(start_date: prev_start,    end_date: prev_end)

      SeoReportMailer.weekly_report(
        current: current, previous: previous,
        summary_current: summary_current, summary_previous: summary_previous,
        analysis: analysis, week_label: week_label
      ).deliver_now
    end

    # Sauvegarde en DB pour l'historique
    save_report(period, label_for(period), current_start, summary_current, current, analysis)

    render json: { ok: true, sent_to: SeoReportMailer::REPORT_TO }
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end

  # GET /api/seo/history?weeks=N&period=weekly|monthly
  def history
    period = params[:period].presence&.strip == "monthly" ? "monthly" : "weekly"
    n      = params[:weeks].present? ? [[params[:weeks].to_i, 1].max, 26].min : 8

    reports = SeoReport.where(period: period).recent(n).map do |r|
      {
        label:       r.label,
        report_date: r.report_date.strftime("%d/%m/%Y"),
        summary:     r.summary_data,
        top_pages:   r.top_pages&.first(10),
        actions:     r.actions
      }
    end

    render json: { period: period, count: reports.size, reports: reports }
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def label_for(period)
    if period == "monthly"
      current_start = Date.today.prev_month.beginning_of_month
      months_fr = %w[janvier février mars avril mai juin juillet août septembre octobre novembre décembre]
      "#{months_fr[current_start.month - 1]} #{current_start.year}"
    else
      wday          = Date.today.wday == 0 ? 7 : Date.today.wday
      current_start = Date.today - wday + 1 - 7
      current_end   = current_start + 6
      "#{current_start.strftime('%d/%m')} au #{current_end.strftime('%d/%m/%Y')}"
    end
  end

  def save_report(period, label, report_date, summary, pages, analysis)
    SeoReport.upsert(
      {
        period:       period,
        label:        label,
        report_date:  report_date,
        summary_data: summary.to_json,
        top_pages:    pages.first(25).to_json,
        analysis:     analysis,
        actions:      [].to_json,
        created_at:   Time.current,
        updated_at:   Time.current
      },
      unique_by: %i[period report_date]
    )
  rescue => e
    Rails.logger.warn("SeoReport save failed: #{e.message}")
  end

  def authenticate!
    token = params[:token] || request.headers["X-SEO-Token"]
    expected = ENV.fetch("SEO_API_TOKEN", nil)
    return head :unauthorized unless expected.present? && ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected)
  end
end
