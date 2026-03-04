class MatchesController < ApplicationController
  def show
    @matchup = Matchup.find_by(slug: params[:slug])

    if @matchup
      @match = @matchup.matches
                        .where("start_time >= ?", Time.current - 3.hours)
                        .order(:start_time)
                        .first
      @match ||= @matchup.matches.order(start_time: :desc).first
    else
      @match = Match.find_by(slug: params[:slug]) || Match.find_by(id: params[:slug])
      @matchup = @match&.matchup
    end

    if @match.nil?
      redirect_to root_path, alert: "Aucune diffusion trouvée pour ce match."
    else
      expires_in 5.minutes, public: true
      @events = fetch_events(@match)
    end
  end

  def live_score
    @match = Match.find_by(slug: params[:slug])
    return render json: { error: 'not found' }, status: :not_found unless @match

    Rails.cache.fetch("live_score_#{@match.api_id}", expires_in: 55.seconds) do
      FootballApiService.new.fetch_fixture_result(@match.api_id)
    end

    match  = @match.reload
    events = fetch_events(match)

    render json: {
      status:     match.status,
      home_score: match.home_score,
      away_score: match.away_score,
      elapsed:    match.elapsed,
      events:     events
    }
  end

  private

  def fetch_events(match)
    Rails.cache.fetch("events_#{match.api_id}", expires_in: match.cache_duration) do
      FootballApiService.new.fetch_fixture_events(match.api_id)
    end
  end
end
