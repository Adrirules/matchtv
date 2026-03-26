namespace :sync do
  desc "Synchronise toutes les ligues et actualise le sitemap pour le SEO"
  task all_leagues: :environment do
    api = FootballApiService.new

    # On récupère la liste des 20 ligues définie dans ton service
    leagues = FootballApiService::SUPPORTED_LEAGUES

    puts "🚀 [#{Time.now.strftime('%H:%M')}] DÉBUT DE LA MÉGA-SYNCHRONISATION"
    puts "--------------------------------------------------"

    midnight_sync = Time.now.hour == 0

    leagues.each do |id, name|
      # Hors minuit, skip les ligues sans match dans les 7 prochains jours
      unless midnight_sync
        has_upcoming = Match.where(competition: name)
                            .where(start_time: Date.today..7.days.from_now)
                            .exists?
        unless has_upcoming
          puts "⏭️  #{name.ljust(20)} — aucun match cette semaine, sync quotidienne"
          next
        end
      end

      print "🔄 Importation de : #{name.ljust(20)} "
      begin
        api.import_upcoming_fixtures(league_id: id)
        puts "✅ OK"
      rescue => e
        puts "❌ ERREUR : #{e.message}"
      end
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
