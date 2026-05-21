namespace :indexnow do
  desc "Soumet un article blog à IndexNow (Bing) — SLUG=mon-article"
  task submit_blog: :environment do
    slug = ENV["SLUG"]
    abort "Usage : SLUG=mon-article rails indexnow:submit_blog" if slug.blank?

    ok = IndexNowService.submit_blog(slug)
    puts ok ? "✅ IndexNow : /blog/#{slug} soumis (Bing + partenaires)" : "❌ Échec pour /blog/#{slug}"
  end

  desc "Soumet tous les articles blog publiés à IndexNow"
  task submit_all_blog: :environment do
    puts "📡 IndexNow — soumission de tous les articles blog..."
    count = IndexNowService.submit_all_blog
    puts "  ✅ #{count} article(s) soumis à IndexNow (Bing + partenaires)"
  end

  desc "Soumet les matchs créés récemment à IndexNow"
  task submit_recent: :environment do
    puts "📡 IndexNow — matchs récents..."
    count = IndexNowService.submit_recent_matches(hours_back: 3)
    if count > 0
      puts "  ✅ #{count} URL(s) soumises à IndexNow"
    else
      puts "  ℹ️  Aucun nouveau match à soumettre"
    end
  end

  desc "Soumet une URL précise à IndexNow — URL=https://..."
  task submit_url: :environment do
    url = ENV["URL"]
    abort "Usage : URL=https://www.coupdenvoi.tv/... rails indexnow:submit_url" if url.blank?

    ok = IndexNowService.new.submit_url(url)
    puts ok ? "✅ IndexNow : #{url} soumis" : "❌ Échec pour #{url}"
  end
end
