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
      if params[:slug] =~ /-\d+$/
        base_slug = params[:slug].sub(/-\d+$/, '')
        base_player = Player.find_by(slug: base_slug)
        redirect_to joueur_path(base_player.slug), status: :moved_permanently and return if base_player
      end
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

    pos_fr    = { "Goalkeeper" => "Gardien", "Defender" => "Défenseur",
                  "Midfielder" => "Milieu",  "Attacker"  => "Attaquant" }
    pos_label = pos_fr[@player.position]
    team      = @team.presence || @player.team_name.presence
    is_short  = @full_name.split.size <= 1

    @page_title = if is_short && pos_label.present? && team.present?
      "#{@full_name} (#{pos_label}, #{team}) — Stats 2025-2026 | Coup d'Envoi TV"
    elsif is_short && team.present?
      "#{@full_name} (#{team}) — Stats 2025-2026 | Coup d'Envoi TV"
    elsif team.present?
      "#{@full_name} (#{team}) — Stats 2025-2026, buts et passes | Coup d'Envoi TV"
    else
      "#{@full_name} — Stats 2025-2026, buts et passes | Coup d'Envoi TV"
    end

    @page_desc = if @games > 0
      pos_str  = pos_label ? "#{pos_label.downcase} " : ""
      team_str = team ? "à #{team} " : ""
      "Statistiques de #{@full_name}, #{pos_str}#{team_str}en 2025-2026 : " \
      "#{@goals} but#{'s' if @goals != 1}, #{@assists} passe#{'s' if @assists != 1}" \
      " décisive#{'s' if @assists != 1} en #{@games} match#{'es' if @games > 1}. " \
      "Programme TV des prochains matchs#{team ? " de #{team}" : ""}."
    else
      pos_str  = pos_label ? "#{pos_label.downcase} " : ""
      team_str = team ? "à #{team}" : ""
      "Profil de #{@full_name}, #{pos_str}#{team_str} pour la saison 2025-2026. " \
      "Statistiques et programme TV des prochains matchs."
    end

    # noindex si contenu trop mince :
    # - 0 stats du tout + aucun match à venir
    # - stats uniquement issues de matchs amicaux + aucun match à venir
    @noindex = (@games.to_i == 0 && @upcoming_matches.empty?) ||
               (@is_friendly && @upcoming_matches.empty?)

    expires_in 6.hours, public: true
  end
end
