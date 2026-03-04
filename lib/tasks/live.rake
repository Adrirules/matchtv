namespace :live do
  desc "Refresh live and recently finished scores from API"
  task refresh: :environment do
    puts "[#{Time.current}] Refreshing live scores..."
    service = FootballApiService.new
    service.fetch_live_scores
    service.fetch_today_results
    puts "[#{Time.current}] Done."
  end
end
