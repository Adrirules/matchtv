namespace :standings do
  desc "Synchronise les classements de toutes les ligues en DB (job daily)"
  task sync: :environment do
    api     = FootballApiService.new
    leagues = FootballApiService::COMPETITIONS_META.select { |c| c[:has_standings] }

    puts "📊 Sync classements — #{leagues.count} ligues..."

    leagues.each do |league|
      print "  #{league[:name].ljust(25)} "

      data = api.get_standings(league[:id])

      if data.blank?
        puts "⚠️  Pas de données"
        next
      end

      standing = Standing.find_or_initialize_by(league_id: league[:id], season: 2025)
      standing.data      = data
      standing.synced_at = Time.current
      standing.save!

      puts "✅ OK"
      sleep 1
    end

    puts "✨ Classements à jour en DB !"
  end
end
