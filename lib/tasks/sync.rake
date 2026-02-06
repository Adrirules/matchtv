namespace :sync do
  desc "Synchronise toutes les ligues majeures pour les 30 prochains jours"
  task all_leagues: :environment do
    api = FootballApiService.new

    # On définit les ligues qu'on veut couvrir (ID API-Football)
    # Tu peux en ajouter autant que tu veux ici !
    leagues_to_sync = {
      61  => "Ligue 1",
      62  => "Ligue 2",
      39  => "Premier League",
      140 => "La Liga",
      78  => "Bundesliga",
      135 => "Serie A",
      2   => "Champions League",
      3   => "Europa League",
      193 => "D1 Féminine",
      141 => "Coupe du Roi",
      529 => "Coupe de France"
    }

    puts "--- DÉBUT DE LA SYNCHRONISATION GLOBALE ---"

    leagues_to_sync.each do |id, name|
      puts "🔄 Importation de : #{name} (ID: #{id})..."
      begin
        result = api.import_upcoming_fixtures(league_id: id, season: 2025)
        puts "✅ #{result}"
      rescue => e
        puts "❌ Erreur sur #{name} : #{e.message}"
      end
    end

    puts "--- SYNCHRONISATION TERMINÉE ---"
  end
end
