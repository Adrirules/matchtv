class TeamsController < ApplicationController

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

    # Cherche les matchs dont le slug de home_team OU away_team correspond
    # On charge tout en SQL puis on filtre en Ruby uniquement sur le slug
    @matches = Match.where("start_time >= ?", Time.current - 3.hours)
                    .order(:start_time)
                    .select { |m| m.home_team&.parameterize == current_slug || m.away_team&.parameterize == current_slug }

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
      @team_name = current_slug.tr('-', ' ').split.map(&:capitalize).join(' ')
    end

    @page_title = "Programme TV #{@team_name} : sur quelle chaîne voir le match ?"
    @page_desc  = "Calendrier complet du #{@team_name} à la télé. Retrouvez les horaires, les chaînes et les diffusions en direct pour la saison 2025/2026."

    expires_in 5.minutes, public: true
  end
end
