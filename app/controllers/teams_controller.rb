class TeamsController < ApplicationController

  def index
    # On reste sur ton index qui est très bon
    home_teams = Match.distinct.pluck(:home_team)
    away_teams = Match.distinct.pluck(:away_team)
    team_names = (home_teams + away_teams).uniq.compact.sort

    @teams = team_names.map do |name|
      {
        name: name,
        slug: name.parameterize,
        logo: Match.where(home_team: name).or(Match.where(away_team: name)).last&.then { |m| m.home_team == name ? m.home_team_logo : m.away_team_logo }
      }
    end
    @page_title = "Toutes les équipes de Football - Programme TV"
  end

  def show
    # 1. On garde le slug brut pour comparer
    current_slug = params[:team_slug]

    # 2. On récupère TOUS les matchs récents/à venir
    # On va filtrer en Ruby pour être CERTAIN que le parameterize correspond parfaitement au slug
    all_potential_matches = Match.where("start_time >= ?", Time.current - 3.hours)
                                 .order(:start_time)

    @matches = all_potential_matches.select do |m|
      m.home_team&.parameterize == current_slug || m.away_team&.parameterize == current_slug
    end

    # 3. On définit le nom de l'équipe et le logo à partir du premier match trouvé
    if @matches.any?
      first_match = @matches.first
      if first_match.home_team&.parameterize == current_slug
        @team_name = first_match.home_team
        @team_logo = first_match.home_team_logo
      else
        @team_name = first_match.away_team
        @team_logo = first_match.away_team_logo
      end
    else
      # Fallback si aucun match à venir : on décode le slug proprement
      @team_name = current_slug.tr('-', ' ').split.map(&:capitalize).join(' ')
    end

    @page_title = "📺 Programme TV #{@team_name} : sur quelle chaîne voir le match ?"
    @page_desc = "Calendrier complet du #{@team_name} à la télé. Retrouvez les horaires, les chaînes et les diffusions en direct pour la saison 2025/2026."
  end
end
