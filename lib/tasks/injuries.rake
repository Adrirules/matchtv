namespace :injuries do
  desc "Pré-fetch les blessures pour les matchs des 7 prochains jours (chauffe le cache)"
  task prefetch: :environment do
    matches = Match.where(status: "NS")
                   .where(start_time: Time.current..(Time.current + 7.days))
                   .where.not(api_id: nil)
                   .order(:start_time)

    if matches.empty?
      puts "✅ Aucun match à venir dans les 7 prochains jours."
      next
    end

    puts "🩹 Pré-fetch blessures pour #{matches.count} matchs..."
    api     = FootballApiService.new
    fetched = 0
    empty   = 0
    errors  = 0

    matches.each_with_index do |match, i|
      begin
        data = api.fetch_injuries(match.api_id)
        if data.is_a?(Array) && data.any?
          fetched += 1
          puts "  ✅ [#{i+1}/#{matches.count}] #{match.home_team} vs #{match.away_team} — #{data.size} absent(s)"
        else
          empty += 1
        end
      rescue => e
        errors += 1
        Rails.logger.error("[injuries:prefetch] #{match.api_id} : #{e.message}")
      end

      sleep 0.5
    end

    puts "Done. #{fetched} avec blessures, #{empty} sans données, #{errors} erreurs."
  end
end
