class PlayersController < ApplicationController
  # Ligues "friendlies" de l'API — pas de valeur éditoriale, on les masque
  FRIENDLY_LEAGUES = %w[
    Friendlies\ Clubs Club\ Friendlies Friendlies\ International
    International\ Friendlies Friendlies
  ].freeze

  def index
    @players = Player.order(:name)
    @page_title = "Tous les joueurs de football — Stats et programme TV | Coup d'Envoi TV"
    @page_desc  = "Retrouvez les statistiques, buts, passes et prochains matchs de tous les joueurs de football pour la saison 2025-2026."
    expires_in 1.hour, public: true
  end

  def show
    @player = Player.find_by(slug: params[:slug])

    if @player.nil?
      render "errors/not_found", status: :not_found and return
    end

    # Valeurs par défaut — évite les nil dans les vues et la description SEO
    @goals = 0; @assists = 0; @games = 0; @rating = nil
    @yellow = 0; @red = 0; @minutes = 0
    @stats = nil; @info = nil; @league = nil; @is_friendly = false

    api = FootballApiService.new
    data = api.fetch_player_stats(@player.api_id)

    if data
      @stats    = data['statistics']&.first
      @info     = data['player']
      raw_league = @stats&.dig('league', 'name')
      @is_friendly = FRIENDLY_LEAGUES.any? { |f| raw_league.to_s.include?(f) }
      @league   = @is_friendly ? nil : raw_league
      @team     = @stats&.dig('team', 'name') || @player.team_name

      # Stats clés
      @goals    = @stats&.dig('goals', 'total').to_i
      @assists  = @stats&.dig('goals', 'assists').to_i
      @games    = @stats&.dig('games', 'appearences').to_i
      @rating   = @stats&.dig('games', 'rating')&.to_f&.round(1)
      @yellow   = @stats&.dig('cards', 'yellow').to_i
      @red      = @stats&.dig('cards', 'red').to_i
      @minutes  = @stats&.dig('games', 'minutes').to_i
    end

    # Nom complet depuis l'API (firstname + lastname) — plus SEO que l'abrégé "M. Gonzalez"
    @full_name = if @info
      "#{@info['firstname']} #{@info['lastname']}".strip.presence || @player.name
    else
      @player.name
    end

    # Prochains matchs de l'équipe du joueur
    @upcoming_matches = Match.where(
      "home_team_api_id = ? OR away_team_api_id = ?",
      @player.team_api_id, @player.team_api_id
    ).where("start_time >= ?", Time.current)
     .order(:start_time)
     .limit(5)

    @page_title = "#{@full_name} — Stats 2025-2026, buts et passes | Coup d'Envoi TV"
    @page_desc  = "Statistiques complètes de #{@full_name} pour la saison 2025-2026 : #{@goals} but#{'s' if @goals != 1}, #{@assists} passe#{'s' if @assists != 1} décisive#{'s' if @assists != 1} en #{@games} match#{'s' if @games != 1}. Programme TV des prochains matchs."

    # noindex si contenu trop mince :
    # - 0 stats du tout + aucun match à venir
    # - stats uniquement issues de matchs amicaux + aucun match à venir
    @noindex = (@games.to_i == 0 && @upcoming_matches.empty?) ||
               (@is_friendly && @upcoming_matches.empty?)

    expires_in 6.hours, public: true
  end
end
