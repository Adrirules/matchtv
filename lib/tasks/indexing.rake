namespace :indexing do
  desc "Soumet à Google les matchs créés dans les 3 dernières heures (à programmer après sync:all_leagues)"
  task submit_recent: :environment do
    puts "📡 [#{Time.now.strftime('%H:%M')}] Indexing API — matchs récents..."

    count = IndexingService.submit_recent_matches(hours_back: 3)

    if count > 0
      puts "  ✅ #{count} URL(s) soumises à Google"
    else
      puts "  ℹ️  Aucun nouveau match à soumettre"
    end
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

  desc "Soumet une URL précise (URL=https://... rails indexing:submit_url)"
  task submit_url: :environment do
    url = ENV["URL"]
    abort "Usage : URL=https://www.coupdenvoi.tv/... rails indexing:submit_url" if url.blank?

    ok = IndexingService.new.send(:notify, url)
    puts ok ? "✅ #{url} soumis" : "❌ Échec pour #{url}"
  end
end
