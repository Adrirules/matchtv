namespace :summaries do
  desc "Génère les résumés Groq pour les matchs terminés sans résumé (30 derniers jours)"
  task generate: :environment do
    matches = Match.where(status: Match::FINISHED_STATUSES)
                   .where(summary: nil)
                   .where("start_time >= ?", 30.days.ago)
                   .order(start_time: :desc)
                   .limit(50)

    if matches.empty?
      puts "✅ Aucun match à traiter."
      next
    end

    puts "🤖 #{matches.count} matchs à résumer..."

    matches.each_with_index do |match, i|
      result = MatchSummaryService.generate(match)
      if result
        puts "  ✅ [#{i+1}/#{matches.count}] #{match.home_team} #{match.home_score}-#{match.away_score} #{match.away_team}"
      else
        puts "  ⚠️  [#{i+1}/#{matches.count}] Échec : #{match.home_team} vs #{match.away_team}"
      end
    end

    puts "🎉 Résumés générés !"
  end
end
