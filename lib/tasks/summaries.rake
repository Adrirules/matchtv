namespace :summaries do
  desc "Génère les résumés Groq pour les matchs terminés sans résumé (30 derniers jours)"
  task generate: :environment do
    matches = Match.where(status: Match::FINISHED_STATUSES)
                   .where(summary: nil)
                   .where("start_time >= ?", 30.days.ago)
                   .order(start_time: :desc)
                   .limit(30)

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
      sleep 4
    end

    puts "🎉 Résumés générés !"
  end

  desc "Enrichit progressivement les matchs historiques sans résumé (par lots de 30, du plus récent au plus ancien)"
  task backfill: :environment do
    batch = (ENV['BATCH'] || 30).to_i

    matches = Match.where(status: Match::FINISHED_STATUSES)
                   .where(summary: nil)
                   .where("start_time < ?", 30.days.ago)
                   .order(start_time: :desc)
                   .limit(batch)

    if matches.empty?
      puts "✅ Tous les matchs historiques ont un résumé."
      next
    end

    total_pending = Match.where(status: Match::FINISHED_STATUSES).where(summary: nil).count
    puts "📦 #{matches.count} matchs à traiter (#{total_pending} restants au total)..."

    ok = 0
    matches.each_with_index do |match, i|
      result = MatchSummaryService.generate(match)
      if result
        ok += 1
        puts "  ✅ [#{i+1}/#{matches.count}] #{match.home_team} #{match.home_score}-#{match.away_score} #{match.away_team} (#{match.competition})"
      else
        puts "  ⚠️  [#{i+1}/#{matches.count}] Échec : #{match.home_team} vs #{match.away_team}"
      end
      sleep 4
    end

    remaining = Match.where(status: Match::FINISHED_STATUSES).where(summary: nil).count
    puts "🎉 #{ok}/#{matches.count} résumés générés. Il reste #{remaining} matchs sans résumé."
  end

  desc "Génère les previews Groq pour les matchs à venir sans preview (7 prochains jours)"
  task previews: :environment do
    matches = Match.where("start_time > ?", Time.current)
                   .where(preview: nil)
                   .where("start_time <= ?", 7.days.from_now)
                   .order(:start_time)
                   .limit(50)

    if matches.empty?
      puts "✅ Aucun match à venir sans preview."
      next
    end

    puts "🤖 #{matches.count} avant-matchs à générer..."

    matches.each_with_index do |match, i|
      result = MatchSummaryService.generate_preview(match)
      if result
        puts "  ✅ [#{i+1}/#{matches.count}] #{match.home_team} vs #{match.away_team} (#{match.competition})"
      else
        puts "  ⚠️  [#{i+1}/#{matches.count}] Échec : #{match.home_team} vs #{match.away_team}"
      end
      sleep 4
    end

    puts "🎉 Previews générés !"
  end
end
