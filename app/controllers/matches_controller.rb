class MatchesController < ApplicationController
  def show
    # 1. On essaie d'abord de trouver un Matchup (ancienne logique)
    @matchup = Matchup.find_by(slug: params[:slug])

    if @matchup
      # Si c'est un Matchup, on garde ta logique : on cherche le match le plus proche
      @match = @matchup.matches
                        .where("start_time >= ?", Time.current - 3.hours)
                        .order(:start_time)
                        .first
      @match ||= @matchup.matches.order(start_time: :desc).first
    else
      # 2. Si ce n'est pas un Matchup, c'est peut-être un Match direct (nouveau lien depuis Team)
      @match = Match.find_by(slug: params[:slug]) || Match.find_by(id: params[:slug])

      # Si on a trouvé le match, on récupère son matchup pour la cohérence de la vue
      @matchup = @match&.matchup if @match
    end

    # 3. Ultime sécurité : si vraiment aucun match n'est trouvé
    if @match.nil?
      redirect_to root_path, alert: "Aucune diffusion trouvée pour ce match."
    else
      expires_in 5.minutes, public: true
      live_statuses     = %w[1H HT 2H ET BT P]
      finished_statuses = %w[FT AET PEN]
      is_live     = live_statuses.include?(@match.status)
      is_finished = finished_statuses.include?(@match.status)

      cache_duration = is_live ? 55.seconds : (is_finished ? 24.hours : 1.hour)

      @events = Rails.cache.fetch("events_#{@match.api_id}", expires_in: cache_duration) do
        FootballApiService.new.fetch_fixture_events(@match.api_id)
      end
    end
  end

  def live_score
    @match = Match.find_by(slug: params[:slug])
    return render json: { error: 'not found' }, status: :not_found unless @match

    # On ne refresh depuis l'API qu'une fois par minute max (cache par match)
    Rails.cache.fetch("live_score_#{@match.api_id}", expires_in: 55.seconds) do
      FootballApiService.new.fetch_fixture_result(@match.api_id)
    end

    match = @match.reload
    live_statuses     = %w[1H HT 2H ET BT P]
    finished_statuses = %w[FT AET PEN]
    is_finished = finished_statuses.include?(match.status)
    cache_duration = live_statuses.include?(match.status) ? 55.seconds : (is_finished ? 24.hours : 1.hour)

    events = Rails.cache.fetch("events_#{match.api_id}", expires_in: cache_duration) do
      FootballApiService.new.fetch_fixture_events(match.api_id)
    end

    render json: {
      status:     match.status,
      home_score: match.home_score,
      away_score: match.away_score,
      elapsed:    match.elapsed,
      events:     events
    }
  end
end
