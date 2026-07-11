namespace :indexing do
  desc "Soumet à Google + IndexNow les matchs créés dans les 3 dernières heures"
  task submit_recent: :environment do
    puts "📡 [#{Time.now.strftime('%H:%M')}] Indexing — matchs récents..."

    # Google Indexing API
    google_count = IndexingService.submit_recent_matches(hours_back: 3)
    puts google_count > 0 ? "  ✅ Google : #{google_count} URL(s)" : "  ℹ️  Google : rien à soumettre"

    # IndexNow (Bing + partenaires)
    bing_count = IndexNowService.submit_recent_matches(hours_back: 3)
    puts bing_count > 0 ? "  ✅ IndexNow : #{bing_count} URL(s)" : "  ℹ️  IndexNow : rien à soumettre"
  end

  desc "Soumet tous les articles blog publiés à Google Indexing API"
  task submit_blog: :environment do
    puts "📡 [#{Time.now.strftime('%H:%M')}] Indexing API — articles blog..."

    blog_path = Rails.root.join("app", "content", "blog", "*.md")
    slugs = Dir.glob(blog_path).filter_map do |f|
      raw  = File.read(f)
      next unless raw.start_with?("---")
      meta = YAML.safe_load(raw.split("---", 3)[1], permitted_classes: [Date]) rescue {}
      next unless meta["published_at"] && meta["published_at"] <= Date.today
      meta["slug"]
    end.compact

    svc   = IndexingService.new
    count = svc.submit_batch(slugs.map { |s| "https://www.coupdenvoi.tv/blog/#{s}" })
    puts "  ✅ #{count} article(s) soumis à Google"
  end

  desc "Soumet les articles blog du jour à Google + IndexNow (scheduler daily)"
  task submit_todays_blog: :environment do
    puts "📡 [#{Time.now.strftime('%H:%M')}] Indexing — articles du jour..."

    # IndexNow (Bing + partenaires) — articles publiés aujourd'hui
    bing_count = IndexNowService.submit_todays_blog
    puts bing_count > 0 ? "  ✅ IndexNow : #{bing_count} article(s) du jour" : "  ℹ️  IndexNow : aucun article publié aujourd'hui"

    # Google Indexing API — mêmes articles
    blog_path = Rails.root.join("app", "content", "blog", "*.md")
    slugs = Dir.glob(blog_path).filter_map do |f|
      raw = File.read(f)
      next unless raw.start_with?("---")
      meta = YAML.safe_load(raw.split("---", 3)[1], permitted_classes: [Date]) rescue {}
      next unless meta["published_at"] == Date.today && meta["slug"]
      pub_time = meta["published_time"].to_s
      if pub_time.match?(/\A\d{1,2}h\d{2}\z/)
        h, m = pub_time.split('h').map(&:to_i)
        next unless Time.current >= Time.zone.local(Date.today.year, Date.today.month, Date.today.day, h, m)
      end
      meta["slug"]
    end.compact

    if slugs.any?
      google_count = IndexingService.new.submit_batch(slugs.map { |s| "https://www.coupdenvoi.tv/blog/#{s}" })
      puts "  ✅ Google : #{google_count} article(s) du jour"
    else
      puts "  ℹ️  Google : aucun article à soumettre"
    end
  end

  desc "Soumet une URL précise à Google + IndexNow (URL=https://...)"
  task submit_url: :environment do
    url = ENV["URL"]
    abort "Usage : URL=https://www.coupdenvoi.tv/... rails indexing:submit_url" if url.blank?

    google_ok = IndexingService.new.send(:notify, url)
    puts google_ok ? "✅ Google : #{url}" : "❌ Google : échec pour #{url}"

    bing_ok = IndexNowService.new.submit_url(url)
    puts bing_ok ? "✅ IndexNow : #{url}" : "❌ IndexNow : échec pour #{url}"
  end
end
