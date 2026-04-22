namespace :rounds do
  desc "Backfill round data for knockout competitions via API"
  task backfill: :environment do
    # Compétitions dont on veut les rounds (knockout ou phases finales)
    knockout_league_ids = [2, 3, 848, 66, 141, 1]

    api = FootballApiService.new
    total_updated = 0

    knockout_league_ids.each do |league_id|
      league_name = FootballApiService::SUPPORTED_LEAGUES[league_id]
      puts "🔄 Backfill rounds : #{league_name} (id=#{league_id})"

      begin
        response = api.send(:client).get('/fixtures', { league: league_id, season: 2025 })
        fixtures = JSON.parse(response.body)['response'] || []

        if fixtures.empty?
          # Try 2026 for World Cup
          response = api.send(:client).get('/fixtures', { league: league_id, season: 2026 })
          fixtures = JSON.parse(response.body)['response'] || []
        end

        if fixtures.empty?
          puts "  ⚠️  Aucun match trouvé"
          next
        end

        updated = 0
        fixtures.each do |data|
          api_id = data['fixture']['id']
          round  = data['league']['round']
          next if round.blank?

          rows = Match.where(api_id: api_id).update_all(round: round)
          updated += rows
        end

        total_updated += updated
        puts "  ✅ #{updated} matchs mis à jour sur #{fixtures.count} fixtures"
      rescue => e
        puts "  ❌ Erreur pour #{league_name}: #{e.message}"
      end

      sleep 1 # Respect rate limit
    end

    puts "\n✅ Backfill terminé — #{total_updated} matchs mis à jour au total"
  end
end
