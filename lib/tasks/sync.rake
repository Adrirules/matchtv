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
end
