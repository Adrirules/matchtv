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

    scope = Match.where(start_time: @date.all_day).order(:start_time)

    # Fetch API uniquement si des scores manquent — SQL au lieu de charger tout en Ruby
    if scope.where(home_score: nil).exists?
      Rails.cache.fetch("results_fetched_#{@date}", expires_in: 1.hour) do
        FootballApiService.new.fetch_date_results(@date)
        true
      end
    end

    @matches = scope.reload
  end
end
