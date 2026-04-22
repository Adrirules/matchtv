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

  # Retourne [{page:, clicks:, impressions:, ctr:, position:}, ...]
  def top_pages(start_date:, end_date:, limit: 25)
    body = {
      startDate:  start_date.to_s,
      endDate:    end_date.to_s,
      dimensions: ["page"],
      rowLimit:   limit,
      orderBy:    [{ fieldName: "impressions", sortOrder: "DESCENDING" }]
    }
    response = query(body)
    return [] unless response["rows"]

    response["rows"].map do |row|
      url = row["keys"][0].gsub("https://www.coupdenvoi.tv", "")
      {
        page:        url.presence || "/",
        clicks:      row["clicks"].to_i,
        impressions: row["impressions"].to_i,
        ctr:         (row["ctr"].to_f * 100).round(1),
        position:    row["position"].to_f.round(1)
      }
    end
  end

  # Métriques globales pour une période
  def summary(start_date:, end_date:)
    body = {
      startDate:  start_date.to_s,
      endDate:    end_date.to_s,
      dimensions: [],
      rowLimit:   1
    }
    response = query(body)
    row = response["rows"]&.first || {}
    {
      clicks:      row["clicks"].to_i,
      impressions: row["impressions"].to_i,
      ctr:         (row["ctr"].to_f * 100).round(1),
      position:    row["position"].to_f.round(1)
    }
  end

  private

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
