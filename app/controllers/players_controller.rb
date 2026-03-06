class PlayersController < ApplicationController

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

    api = FootballApiService.new
    data = api.fetch_player_stats(@player.api_id)

    if data
      @stats    = data['statistics']&.first
      @info     = data['player']
      @league   = @stats&.dig('league', 'name')
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

    # Prochains matchs de l'équipe du joueur
    @upcoming_matches = Match.where(
      "home_team_api_id = ? OR away_team_api_id = ?",
      @player.team_api_id, @player.team_api_id
    ).where("start_time >= ?", Time.current)
     .order(:start_time)
     .limit(5)

    @page_title = "#{@player.name} — Stats 2025-2026, buts et passes | Coup d'Envoi TV"
    @page_desc  = "Statistiques complètes de #{@player.name} pour la saison 2025-2026 : #{@goals} but#{'s' if @goals != 1}, #{@assists} passe#{'s' if @assists != 1} décisive#{'s' if @assists != 1} en #{@games} match#{'s' if @games != 1}. Programme TV des prochains matchs."

    expires_in 6.hours, public: true
  end
end
