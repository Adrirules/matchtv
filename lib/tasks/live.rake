namespace :live do
  desc "Refresh live and recently finished scores from API"
  task refresh: :environment do
    # Ne taper l'API que si un match est en cours ou démarre dans les 2h
    has_activity = Match.where(status: ['1H', 'HT', '2H', 'ET', 'BT', 'P'])
                        .or(Match.where(start_time: 3.hours.ago..2.hours.from_now))
                        .exists?

    unless has_activity
      puts "[#{Time.current}] Aucun match actif ou imminent — skip API."
      next
    end

    puts "[#{Time.current}] Refreshing live scores..."
    service = FootballApiService.new
    service.fetch_live_scores
    service.fetch_today_results
    puts "[#{Time.current}] Done."
  end
end
