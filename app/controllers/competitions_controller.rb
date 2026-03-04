class CompetitionsController < ApplicationController
  def index
    # Un seul appel SQL : on récupère compétition + logo en une passe
    thumbnails = Match.where.not(home_team_logo: nil)
                      .pluck(:competition, :home_team_logo)
                      .each_with_object({}) { |(comp, logo), h| h[comp] ||= logo }

    @competitions = thumbnails.keys.compact.sort.map do |comp_name|
      { name: comp_name, slug: comp_name.parameterize, thumbnail: thumbnails[comp_name] }
    end

    @page_title = "Toutes les compétitions de Football - Programme TV"
  end

  def show
    @competition_name = params[:slug].tr('-', ' ').titleize

    @matches = Match.where("competition ILIKE ?", "%#{@competition_name}%")
                    .where("start_time >= ?", Time.current - 3.hours)
                    .order(:start_time)

    @page_title = "Programme TV #{@competition_name} : calendrier et chaînes"

    expires_in 5.minutes, public: true
  end
end
