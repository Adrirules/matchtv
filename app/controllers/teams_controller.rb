class TeamsController < ApplicationController

  def index
    # On récupère tous les noms uniques (Home + Away)
    home_teams = Match.distinct.pluck(:home_team)
    away_teams = Match.distinct.pluck(:away_team)

    # On fusionne, on enlève les doublons, on trie par ordre alphabétique
    team_names = (home_teams + away_teams).uniq.compact.sort

    @teams = team_names.map do |name|
      {
        name: name,
        slug: name.parameterize,
        # On prend le logo du dernier match où cette équipe apparaît
        logo: Match.where("home_team = ? OR away_team = ?", name, name).last&.home_team_logo
      }
    end

    @page_title = "Toutes les équipes de Football - Programme TV"
  end


  def show
    @team_name = params[:team_slug].tr('-', ' ').titleize

    @matches = Match.where("home_team ILIKE ? OR away_team ILIKE ?", "%#{@team_name}%", "%#{@team_name}%")
                    .where("start_time >= ?", Time.current - 2.hours)
                    .order(:start_time)

    # L'astuce de l'expert : On chope le logo dans le premier match trouvé
    sample = @matches.first || Match.where("home_team ILIKE ?", "%#{@team_name}%").last || Match.where("away_team ILIKE ?", "%#{@team_name}%").last
    if sample
      @team_logo = sample.home_team.parameterize == params[:team_slug] ? sample.home_team_logo : sample.away_team_logo
    end

    @page_title = "Programme TV #{@team_name} : sur quelle chaîne voir le match ?"
    @page_desc = "Calendrier complet du #{@team_name} à la télé. Ne ratez aucune retransmission en direct."
  end
end
