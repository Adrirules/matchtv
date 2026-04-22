class GscService
  SITE_URL    = "sc-domain:coupdenvoi.tv".freeze
  ENCODED_URL = "sc-domain%3Acoupdenvoi.tv".freeze
  BASE_URL    = "https://searchconsole.googleapis.com/webmasters/v3".freeze
  SCOPE       = "https://www.googleapis.com/auth/webmasters.readonly".freeze

  def initialize
    creds_json = ENV.fetch("GSC_CREDENTIALS")
    @credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(creds_json),
      scope: SCOPE
    )
    @credentials.fetch_access_token!
  end

  # Pages : [{page:, clicks:, impressions:, ctr:, position:, type:}, ...]
  def top_pages(start_date:, end_date:, limit: 50)
    rows = query(
      startDate:  start_date.to_s,
      endDate:    end_date.to_s,
      dimensions: ["page"],
      rowLimit:   limit,
      orderBy:    [{ fieldName: "impressions", sortOrder: "DESCENDING" }]
    )["rows"] || []

    rows.map do |row|
      url = row["keys"][0].gsub("https://www.coupdenvoi.tv", "")
      url = "/" if url.blank?
      {
        page:        url,
        type:        page_type(url),
        clicks:      row["clicks"].to_i,
        impressions: row["impressions"].to_i,
        ctr:         (row["ctr"].to_f * 100).round(1),
        position:    row["position"].to_f.round(1)
      }
    end
  end

  # Top requêtes avec filtre : impressions > 50 OU clics > 0
  # Retourne [{query:, clicks:, impressions:, ctr:, position:}, ...]
  def top_queries(start_date:, end_date:, limit: 200)
    rows = query(
      startDate:  start_date.to_s,
      endDate:    end_date.to_s,
      dimensions: ["query"],
      rowLimit:   500,
      orderBy:    [{ fieldName: "impressions", sortOrder: "DESCENDING" }]
    )["rows"] || []

    rows
      .select { |r| r["impressions"].to_i > 50 || r["clicks"].to_i > 0 }
      .first(limit)
      .map do |row|
        {
          query:       row["keys"][0],
          clicks:      row["clicks"].to_i,
          impressions: row["impressions"].to_i,
          ctr:         (row["ctr"].to_f * 100).round(1),
          position:    row["position"].to_f.round(1)
        }
      end
  end

  # Requêtes x pages — pour détecter la cannibalisation
  # Retourne [{query:, page:, type:, clicks:, impressions:, ctr:, position:}, ...]
  def queries_by_page(start_date:, end_date:, limit: 200)
    rows = query(
      startDate:  start_date.to_s,
      endDate:    end_date.to_s,
      dimensions: ["query", "page"],
      rowLimit:   500,
      orderBy:    [{ fieldName: "impressions", sortOrder: "DESCENDING" }]
    )["rows"] || []

    rows
      .select { |r| r["impressions"].to_i > 30 || r["clicks"].to_i > 0 }
      .first(limit)
      .map do |row|
        url = row["keys"][1].gsub("https://www.coupdenvoi.tv", "")
        {
          query:       row["keys"][0],
          page:        url.presence || "/",
          type:        page_type(url.presence || "/"),
          clicks:      row["clicks"].to_i,
          impressions: row["impressions"].to_i,
          ctr:         (row["ctr"].to_f * 100).round(1),
          position:    row["position"].to_f.round(1)
        }
      end
  end

  # Métriques globales
  def summary(start_date:, end_date:)
    rows = query(
      startDate:  start_date.to_s,
      endDate:    end_date.to_s,
      dimensions: ["date"],
      rowLimit:   90
    )["rows"] || []

    totals = rows.each_with_object({ clicks: 0, impressions: 0 }) do |r, h|
      h[:clicks]      += r["clicks"].to_i
      h[:impressions] += r["impressions"].to_i
    end
    avg_ctr = totals[:impressions] > 0 ? ((totals[:clicks].to_f / totals[:impressions]) * 100).round(1) : 0.0
    all_positions = rows.map { |r| r["position"].to_f }.reject(&:zero?)
    avg_pos = all_positions.any? ? (all_positions.sum / all_positions.size).round(1) : 0.0

    totals.merge(ctr: avg_ctr, position: avg_pos)
  end

  private

  def page_type(url)
    case url
    when /^\/matches\//      then "match"
    when /^\/competitions\// then "competition"
    when /^\/classements\//  then "classement"
    when /^\/equipes\//      then "equipe"
    when /^\/joueurs\//      then "joueur"
    when /^\/blog\//         then "blog"
    when /^\/chaines\//      then "chaine"
    when /^\/resultats/      then "listing"
    when /^\/(programme)/    then "listing"
    when /^\/$/, ""          then "home"
    else                          "autre"
    end
  end

  def query(body)
    conn = Faraday.new do |f|
      f.request :json
      f.response :json
    end
    resp = conn.post("#{BASE_URL}/sites/#{ENCODED_URL}/searchAnalytics/query") do |req|
      req.headers["Authorization"] = "Bearer #{@credentials.access_token}"
      req.headers["Content-Type"]  = "application/json"
      req.body = body.to_json
    end
    resp.body.is_a?(Hash) ? resp.body : {}
  rescue => e
    Rails.logger.error "[GscService] Erreur: #{e.message}"
    {}
  end
end
