class TeamsController < ApplicationController
  helper TeamContentHelper

  def index
    # Un seul appel SQL : on récupère nom + logo en une passe
    logos_by_team = Match.where.not(home_team_logo: nil)
                         .pluck(:home_team, :home_team_logo, :away_team, :away_team_logo)
                         .each_with_object({}) do |(ht, hl, at, al), h|
                           h[ht] ||= hl
                           h[at] ||= al
                         end

    @teams = logos_by_team.keys.compact.sort.map do |name|
      { name: name, slug: name.parameterize, logo: logos_by_team[name] }
    end

    @page_title = "Toutes les équipes de Football - Programme TV"
  end

  def show
    current_slug = params[:team_slug]

    # Filtrage précis par slug en Ruby (noms composés, accents, etc.)
    all_team_matches = Match.order(:start_time)
                            .select { |m| m.home_team&.parameterize == current_slug || m.away_team&.parameterize == current_slug }

    # Nom, logo et api_id depuis n'importe quel match (préférer ceux avec api_id renseigné)
    ref_match = all_team_matches.find { |m|
      m.home_team&.parameterize == current_slug && m.home_team_api_id.present?
    } || all_team_matches.find { |m|
      m.away_team&.parameterize == current_slug && m.away_team_api_id.present?
    } || all_team_matches.first

    if ref_match
      if ref_match.home_team&.parameterize == current_slug
        @team_name   = ref_match.home_team
        @team_logo   = ref_match.home_team_logo
        @team_api_id = ref_match.home_team_api_id
      else
        @team_name   = ref_match.away_team
        @team_logo   = ref_match.away_team_logo
        @team_api_id = ref_match.away_team_api_id
      end
    else
      @team_name = current_slug.tr('-', ' ').split.map(&:capitalize).join(' ')
    end

    @matches = all_team_matches.select { |m| m.start_time >= Time.current - 3.hours }

    # Stats & résultats enrichis via API (cachés)
    if @team_api_id.present?
      api = FootballApiService.new

      # Trouver la ligue principale de cette équipe (première compétition SUPPORTED trouvée)
      primary_league_id = FootballApiService::SUPPORTED_LEAGUES.key(
        all_team_matches.map(&:competition).compact.first
      )

      if primary_league_id
        @stats   = api.fetch_team_stats(@team_api_id, primary_league_id)
        standings_data = api.get_standings(primary_league_id)
        @standing = standings_data
                      &.dig(0, "league", "standings", 0)
                      &.find { |s| s["team"]["id"] == @team_api_id }
      end

      @recent_results = api.fetch_recent_results(@team_api_id)
    end

    # Effectif de l'équipe (depuis la DB players)
    @squad = @team_api_id.present? ? Player.where(team_api_id: @team_api_id).order(:position, :name) : []

    @page_title = "#{@team_name} 2025-2026 — Stats, résultats et programme TV | Coup d'Envoi TV"
    @page_desc  = "Retrouvez tous les matchs de #{@team_name} à la télé : horaires, chaînes (Canal+, beIN, DAZN, France TV), résultats et statistiques de la saison 2025-2026."

    expires_in 10.minutes, public: true
  end
end
