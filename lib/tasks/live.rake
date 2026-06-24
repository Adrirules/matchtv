namespace :live do
  desc "Refresh live and recently finished scores from API"
  task refresh: :environment do
    service = FootballApiService.new

    # 1. Scores live + matchs du jour — uniquement si activité en cours ou imminente
    has_activity = Match.where(status: Match::LIVE_STATUSES)
                        .or(Match.where(start_time: 3.hours.ago..2.hours.from_now))
                        .exists?

    if has_activity
      puts "[#{Time.current}] Refreshing live scores..."
      service.fetch_live_scores
      service.fetch_today_results
    else
      puts "[#{Time.current}] Aucun match actif ou imminent — skip live."
    end

    # 2. Rattrapage : matchs d'hier sans score (quota coupé la veille, NS bloqués, etc.)
    # On cible home_score nil = score manquant, peu importe le status en DB.
    # fetch_fixture_result par match évite le filtre status de fetch_date_results
    # qui ne retourne pas les NS → score irrécupérable autrement.
    stuck_yesterday = Match.where(start_time: Date.yesterday.beginning_of_day..Date.yesterday.end_of_day)
                           .where(home_score: nil)
                           .where('start_time < ?', Time.current - 2.hours)
    if stuck_yesterday.exists?
      count = stuck_yesterday.count
      puts "[#{Time.current}] #{count} matchs d'hier sans score — rattrapage individuel..."
      stuck_yesterday.find_each { |m| service.fetch_fixture_result(m.api_id) }
    end

    puts "[#{Time.current}] Done."
  end
end
