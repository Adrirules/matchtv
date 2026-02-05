namespace :sync do
  desc "Synchronise les matchs de Ligue 1 2026"
  task football: :environment do
    service = FootballApiService.new
    # Ligue 1 = 61, Premier League = 39, etc.
    [61, 39, 140].each do |league_id|
      puts "Syncing league #{league_id}..."
      service.import_upcoming_fixtures(league_id: league_id, season: 2025)
    end
  end
end
