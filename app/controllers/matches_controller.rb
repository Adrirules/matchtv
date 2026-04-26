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

      # noindex : match terminé depuis plus de 6 mois sans résumé = page vide sans valeur
      @noindex = @match.finished? && @match.start_time < 6.months.ago && @match.summary.blank?

      @events = fetch_events(@match)
      if @match.home_team_api_id.present? && @match.away_team_api_id.present?
        @head_to_head = fetch_head_to_head(@match)
      end
      @injuries = fetch_injuries(@match)

      # Matchs du même jour (même compétition en priorité, sinon tous)
      day_start = @match.start_time.beginning_of_day
      day_end   = @match.start_time.end_of_day
      @same_day_matches = Match.where(start_time: day_start..day_end)
                               .where.not(id: @match.id)
                               .where.not(slug: [nil, ""])
                               .order(:start_time)
                               .limit(12)
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
    # Matchs terminés depuis plus de 24h : on retourne le cache s'il existe, sinon []
    # (pas d'appel API — les events ne changent plus et le cache file_store est vidé au restart)
    if match.finished? && match.start_time < 24.hours.ago
      return Rails.cache.read("events_#{match.api_id}") || []
    end
    Rails.cache.fetch("events_#{match.api_id}", expires_in: match.cache_duration) do
      FootballApiService.new.fetch_fixture_events(match.api_id)
    end
  end

  def fetch_head_to_head(match)
    # Même logique : h2h stable pour les matchs anciens, pas d'appel API si cache froid
    if match.finished? && match.start_time < 24.hours.ago
      return Rails.cache.read("h2h_#{match.home_team_api_id}_#{match.away_team_api_id}") || []
    end
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
