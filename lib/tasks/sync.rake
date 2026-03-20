namespace :sync do
  desc "Synchronise toutes les ligues et actualise le sitemap pour le SEO"
  task all_leagues: :environment do
    api = FootballApiService.new

    # On récupère la liste des 20 ligues définie dans ton service
    leagues = FootballApiService::SUPPORTED_LEAGUES

    puts "🚀 [#{Time.now.strftime('%H:%M')}] DÉBUT DE LA MÉGA-SYNCHRONISATION"
    puts "--------------------------------------------------"

    leagues.each do |id, name|
      print "🔄 Importation de : #{name.ljust(20)} "
      begin
        # On appelle ton service d'import
        api.import_upcoming_fixtures(league_id: id)
        puts "✅ OK"
      rescue => e
        puts "❌ ERREUR : #{e.message}"
      end
      # Pause de 1 seconde pour respecter les quotas de l'API
      sleep 1
    end

    puts "--------------------------------------------------"
    puts "✨ TOUT EST À JOUR : Tes matchs sont prêts pour Google !"
  end

  desc "Import historique saison 2025-2026 (juillet 2025 → hier) — à lancer une seule fois"
  task historical: :environment do
    api       = FootballApiService.new
    from_date = Date.new(2025, 7, 1)
    to_date   = Date.yesterday
    total     = 0

    puts "📦 Import historique : #{from_date} → #{to_date}"
    puts "   #{FootballApiService::SUPPORTED_LEAGUES.count} ligues · ~#{FootballApiService::SUPPORTED_LEAGUES.count} appels API"
    puts "--------------------------------------------------"

    FootballApiService::SUPPORTED_LEAGUES.each do |id, name|
      print "  #{name.ljust(25)} "
      begin
        result = api.import_historical_fixtures(
          league_id: id,
          season:    2025,
          from_date: from_date,
          to_date:   to_date
        )
        count = result[/\d+/].to_i
        total += count
        puts "✅ #{result}"
      rescue => e
        puts "❌ #{e.message}"
      end
      sleep 1
    end

    puts "--------------------------------------------------"
    puts "✨ Terminé — #{total} matchs historiques importés au total"
  end
end
