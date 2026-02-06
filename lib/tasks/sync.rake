namespace :sync do
  desc "Synchronise toutes les ligues définies dans le service"
  task all_leagues: :environment do
    api = FootballApiService.new

    # On récupère la liste des ligues directement depuis le service
    # C'est ça "boucler sur SUPPORTED_LEAGUES"
    leagues = FootballApiService::SUPPORTED_LEAGUES

    puts "🚀 DÉBUT DE LA SYNCHRONISATION GLOBALE"
    puts "--------------------------------------"

    leagues.each do |id, name|
      puts "🔄 Importation de : #{name} (ID: #{id})..."
      begin
        # On lance l'import pour chaque ligue
        result = api.import_upcoming_fixtures(league_id: id)
        puts "✅ #{result}"
      rescue => e
        puts "❌ Erreur sur #{name} : #{e.message}"
      end
      # On attend 1 seconde pour ne pas brusquer l'API
      sleep 1
    end

    puts "--------------------------------------"
    puts "✨ TOUTES LES LIGUES SONT À JOUR !"
  end
end
