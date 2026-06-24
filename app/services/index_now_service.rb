class IndexNowService
  ENDPOINT = "https://api.indexnow.org/indexnow".freeze
  SITE     = "https://www.coupdenvoi.tv".freeze
  KEY      = "327ed572c0504e44a73b1e283054e307".freeze
  KEY_URL  = "#{SITE}/#{KEY}.txt".freeze

  # Soumet un tableau d'URLs en un seul POST batch (max 10 000)
  def submit_batch(urls)
    return 0 if urls.empty?

    conn = Faraday.new do |f|
      f.request  :json
      f.response :json
    end

    resp = conn.post(ENDPOINT) do |req|
      req.headers["Content-Type"] = "application/json; charset=utf-8"
      req.body = {
        host:       "www.coupdenvoi.tv",
        key:        KEY,
        keyLocation: KEY_URL,
        urlList:    urls.first(10_000)
      }.to_json
    end

    # IndexNow retourne 200 (OK) ou 202 (Accepted)
    if resp.status.in?([200, 202])
      Rails.logger.info("[IndexNow] #{urls.size} URL(s) soumises avec succès")
      urls.size
    else
      Rails.logger.warn("[IndexNow] #{resp.status} — #{resp.body.to_s.truncate(300)}")
      0
    end
  rescue => e
    Rails.logger.warn("[IndexNow] Exception: #{e.message}")
    0
  end

  # Soumet une seule URL (GET simple, plus léger pour un article unique)
  def submit_url(url)
    conn = Faraday.new
    resp = conn.get(ENDPOINT, {
      url:    url,
      key:    KEY
    })

    if resp.status.in?([200, 202])
      Rails.logger.info("[IndexNow] ✅ #{url}")
      true
    else
      Rails.logger.warn("[IndexNow] #{resp.status} pour #{url}: #{resp.body.to_s.truncate(200)}")
      false
    end
  rescue => e
    Rails.logger.warn("[IndexNow] Exception #{url}: #{e.message}")
    false
  end

  # --- Helpers de classe ---

  def self.submit_blog(slug)
    new.submit_url("#{SITE}/blog/#{slug}")
  end

  def self.submit_recent_matches(hours_back: 3)
    slugs = Match.where("created_at > ?", hours_back.hours.ago)
                 .where(start_time: Time.current..7.days.from_now)
                 .where.not(slug: [nil, ""])
                 .pluck(:slug)

    return 0 if slugs.empty?
    new.submit_batch(slugs.map { |s| "#{SITE}/matches/#{s}" })
  end

  def self.submit_all_blog
    blog_path = Rails.root.join("app", "content", "blog", "*.md")
    slugs = Dir.glob(blog_path).filter_map do |f|
      raw = File.read(f)
      next unless raw.start_with?("---")
      meta = YAML.safe_load(raw.split("---", 3)[1], permitted_classes: [Date]) rescue {}
      next unless meta["published_at"] && meta["published_at"] <= Date.today
      meta["slug"]
    end.compact

    return 0 if slugs.empty?
    new.submit_batch(slugs.map { |s| "#{SITE}/blog/#{s}" })
  end

  # Articles publiés aujourd'hui (date + heure atteintes)
  def self.submit_todays_blog
    blog_path = Rails.root.join("app", "content", "blog", "*.md")
    slugs = Dir.glob(blog_path).filter_map do |f|
      raw = File.read(f)
      next unless raw.start_with?("---")
      meta = YAML.safe_load(raw.split("---", 3)[1], permitted_classes: [Date]) rescue {}
      next unless meta["published_at"] == Date.today && meta["slug"]

      # Vérifier que l'heure de publication est passée
      pub_time = meta["published_time"].to_s
      if pub_time.match?(/\A\d{1,2}h\d{2}\z/)
        h, m = pub_time.split('h').map(&:to_i)
        next unless Time.current >= Time.zone.local(Date.today.year, Date.today.month, Date.today.day, h, m)
      end

      meta["slug"]
    end.compact

    return 0 if slugs.empty?
    new.submit_batch(slugs.map { |s| "#{SITE}/blog/#{s}" })
  end
end
