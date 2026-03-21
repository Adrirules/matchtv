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
      if @match.home_team_api_id.present? && @match.away_team_api_id.present?
        @head_to_head = fetch_head_to_head(@match)
      end
      @injuries = fetch_injuries(@match)
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

  def fetch_head_to_head(match)
    Rails.cache.fetch("h2h_#{match.home_team_api_id}_#{match.away_team_api_id}", expires_in: 7.days) do
      FootballApiService.new.fetch_head_to_head(match.home_team_api_id, match.away_team_api_id)
    end
  end

  def fetch_injuries(match)
    ttl = match.finished? ? 30.days : 6.hours
    Rails.cache.fetch("injuries_#{match.api_id}", expires_in: ttl) do
      FootballApiService.new.fetch_injuries(match.api_id)
    end
  end
end
