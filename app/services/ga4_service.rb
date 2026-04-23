class Ga4Service
  PROPERTY_ID = "327137860".freeze
  BASE_URL    = "https://analyticsdata.googleapis.com/v1beta/properties/#{PROPERTY_ID}".freeze
  SCOPE       = "https://www.googleapis.com/auth/analytics.readonly".freeze

  def initialize
    # Réutilise les mêmes credentials que GSC — scope différent
    creds_json = ENV.fetch("GSC_CREDENTIALS")
    @credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(creds_json),
      scope: SCOPE
    )
    @credentials.fetch_access_token!
  end

  # Métriques globales du site sur la période
  def summary(start_date:, end_date:)
    rows = report(
      date_ranges: [{ startDate: start_date.to_s, endDate: end_date.to_s }],
      metrics: %w[sessions activeUsers newUsers bounceRate averageSessionDuration screenPageViews screenPageViewsPerSession]
    )
    m = rows.first&.dig("metricValues") || []
    {
      sessions:          m[0]&.dig("value").to_i,
      users:             m[1]&.dig("value").to_i,
      new_users:         m[2]&.dig("value").to_i,
      bounce_rate:       m[3]&.dig("value").to_f.round(1),
      avg_duration:      m[4]&.dig("value").to_f.round(0).to_i,
      pageviews:         m[5]&.dig("value").to_i,
      pages_per_session: m[6]&.dig("value").to_f.round(2)
    }
  end

  # Top pages avec volume + engagement
  def top_pages(start_date:, end_date:, limit: 50)
    rows = report(
      date_ranges: [{ startDate: start_date.to_s, endDate: end_date.to_s }],
      dimensions:  %w[pagePath],
      metrics:     %w[sessions activeUsers bounceRate averageSessionDuration screenPageViews],
      limit:       limit,
      order_by:    { metric: "sessions", desc: true }
    )

    rows.map do |row|
      path = row.dig("dimensionValues", 0, "value") || "/"
      path = "/" if path == "(not set)"
      m    = row["metricValues"] || []
      {
        page:         path,
        type:         page_type(path),
        sessions:     m[0]&.dig("value").to_i,
        users:        m[1]&.dig("value").to_i,
        bounce_rate:  m[2]&.dig("value").to_f.round(1),
        avg_duration: m[3]&.dig("value").to_f.round(0).to_i,
        pageviews:    m[4]&.dig("value").to_i
      }
    end
  end

  # Agrégats par section (match/blog/competition/equipe...) — calculé depuis top_pages
  def by_section(pages)
    pages.group_by { |p| p[:type] }.transform_values do |arr|
      {
        sessions:     arr.sum { |p| p[:sessions] },
        users:        arr.sum { |p| p[:users] },
        pageviews:    arr.sum { |p| p[:pageviews] },
        avg_bounce:   arr.any? ? (arr.sum { |p| p[:bounce_rate] } / arr.size).round(1) : 0,
        avg_duration: arr.any? ? (arr.sum { |p| p[:avg_duration] } / arr.size).round(0) : 0,
        top_pages:    arr.sort_by { |p| -p[:sessions] }.first(5).map { |p| p.slice(:page, :sessions, :avg_duration, :bounce_rate) }
      }
    end
  end

  # Sources de trafic (Organic, Direct, Social, Referral, Email...)
  def traffic_sources(start_date:, end_date:)
    rows = report(
      date_ranges: [{ startDate: start_date.to_s, endDate: end_date.to_s }],
      dimensions:  %w[sessionDefaultChannelGroup],
      metrics:     %w[sessions activeUsers bounceRate averageSessionDuration],
      limit:       20,
      order_by:    { metric: "sessions", desc: true }
    )

    rows.map do |row|
      m = row["metricValues"] || []
      {
        channel:      row.dig("dimensionValues", 0, "value") || "Unknown",
        sessions:     m[0]&.dig("value").to_i,
        users:        m[1]&.dig("value").to_i,
        bounce_rate:  m[2]&.dig("value").to_f.round(1),
        avg_duration: m[3]&.dig("value").to_f.round(0).to_i
      }
    end
  end

  private

  def page_type(path)
    case path
    when /^\/matches\//      then "match"
    when /^\/competitions\// then "competition"
    when /^\/classements\//  then "classement"
    when /^\/equipes\//      then "equipe"
    when /^\/joueurs\//      then "joueur"
    when /^\/blog\//         then "blog"
    when /^\/chaines\//      then "chaine"
    when /^\/resultats/      then "resultats"
    when /^\/days\//         then "programme"
    when /^\/$/, ""          then "home"
    else                          "autre"
    end
  end

  def report(date_ranges:, metrics:, dimensions: [], limit: 50, order_by: nil)
    body = {
      dateRanges: date_ranges,
      metrics:    metrics.map { |m| { name: m } },
      limit:      limit
    }
    body[:dimensions] = dimensions.map { |d| { name: d } } if dimensions.any?
    body[:orderBys]   = [{ metric: { metricName: order_by[:metric] }, desc: order_by[:desc] }] if order_by

    conn = Faraday.new do |f|
      f.request :json
      f.response :json
    end
    resp = conn.post("#{BASE_URL}:runReport") do |req|
      req.headers["Authorization"] = "Bearer #{@credentials.access_token}"
      req.headers["Content-Type"]  = "application/json"
      req.body = body.to_json
    end

    data = resp.body
    data.is_a?(Hash) ? (data["rows"] || []) : []
  rescue => e
    Rails.logger.error "[Ga4Service] Erreur: #{e.message}"
    []
  end
end
