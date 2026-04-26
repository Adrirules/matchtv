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

    # 2. Rattrapage : matchs d'hier encore bloqués en NS/live (quota coupé la veille)
    yesterday_stuck = Match.where(start_time: Date.yesterday.beginning_of_day..Date.yesterday.end_of_day)
                           .where.not(status: Match::FINISHED_STATUSES)
                           .where('start_time < ?', Time.current - 2.hours)
                           .exists?
    if yesterday_stuck
      puts "[#{Time.current}] Matchs d'hier non finalisés — rattrapage résultats..."
      service.fetch_date_results(Date.yesterday)
    end

    puts "[#{Time.current}] Done."
  end
end
