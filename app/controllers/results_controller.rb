class ResultsController < ApplicationController
  def show
    today = Date.today

    @date =
      if params[:date]
        Date.parse(params[:date])
      else
        today - 1.day
      end

    # Sécurité : jamais dans le futur
    @date = today - 1.day if @date >= today

    # Fenêtre de 7 jours vers le passé
    @days = (1..7).map { |i| today - i.days }

    @matches = Match.where(start_time: @date.all_day).order(:start_time)

    # Fetch les scores depuis l'API si on n'a pas encore les résultats pour ce jour
    # Cache 1h pour éviter de sur-appeler l'API
    if @matches.any? { |m| m.home_score.nil? }
      Rails.cache.fetch("results_fetched_#{@date}", expires_in: 1.hour) do
        FootballApiService.new.fetch_date_results(@date)
        true
      end
      @matches = Match.where(start_time: @date.all_day).order(:start_time)
    end
  end
end
