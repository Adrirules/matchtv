class IndexingService
  ENDPOINT = "https://indexing.googleapis.com/v3/urlNotifications:publish".freeze
  SCOPE     = "https://www.googleapis.com/auth/indexing".freeze
  SITE      = "https://www.coupdenvoi.tv".freeze
  DAILY_CAP = 150 # quota Google = 200/jour, on garde une marge

  def initialize
    creds_json   = ENV.fetch("GSC_CREDENTIALS")
    @credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(creds_json),
      scope:       SCOPE
    )
    @credentials.fetch_access_token!
  end

  # Soumet un tableau d'URLs, retourne le nombre de succès
  def submit_batch(urls)
    submitted = 0
    urls.first(DAILY_CAP).each do |url|
      break if submitted >= DAILY_CAP
      ok = notify(url)
      submitted += 1 if ok
      sleep 0.5 # respecte le rate limit (600 req/min max)
    end
    submitted
  end

  # --- Helpers de classe ---

  # Matchs créés dans les N dernières heures, à venir dans les 7 jours
  def self.submit_recent_matches(hours_back: 3)
    matches = Match.where("created_at > ?", hours_back.hours.ago)
                   .where(start_time: Time.current..7.days.from_now)
                   .pluck(:slug)
                   .compact

    return 0 if matches.empty?

    urls = matches.map { |slug| "#{SITE}/matches/#{slug}" }
    new.submit_batch(urls)
  end

  def self.submit_match(match)
    new.notify("#{SITE}/matches/#{match.slug}")
  end

  def self.submit_blog(slug)
    new.notify("#{SITE}/blog/#{slug}")
  end

  private

  def notify(url, type: "URL_UPDATED")
    conn = Faraday.new do |f|
      f.request  :json
      f.response :json
    end

    resp = conn.post(ENDPOINT) do |req|
      req.headers["Authorization"] = "Bearer #{@credentials.access_token}"
      req.headers["Content-Type"]  = "application/json"
      req.body = { url: url, type: type }.to_json
    end

    unless resp.success?
      Rails.logger.warn("[IndexingService] #{resp.status} pour #{url}: #{resp.body.to_s.truncate(200)}")
      return false
    end

    true
  rescue => e
    Rails.logger.warn("[IndexingService] Exception #{url}: #{e.message}")
    false
  end
end
