class CompetitionsController < ApplicationController
  def index
    # On récupère les noms uniques
    names = Match.distinct.pluck(:competition)

    # On construit le tableau
    # .compact enlève les valeurs nil au cas où une ligne en BDD n'aurait pas de nom de compétition
    @competitions = names.compact.map do |comp_name|
      {
        name: comp_name,
        slug: comp_name.parameterize,
        thumbnail: Match.where(competition: comp_name).where.not(home_team_logo: nil).first&.home_team_logo
      }
    end

    # Sécurité ultime : si @competitions est toujours nil pour une raison obscure, on l'initialise à vide
    @competitions ||= []

    @page_title = "Toutes les compétitions de Football - Programme TV"
  end

  def show
    # .tr('-', ' ') est plus robuste que .gsub pour les slugs simples
    @competition_name = params[:slug].tr('-', ' ').titleize

    @matches = Match.where("competition ILIKE ?", "%#{@competition_name}%")
                    .where("start_time >= ?", Time.current - 3.hours)
                    .order(:start_time)

    @page_title = "Programme TV #{@competition_name} : calendrier et chaînes"
  end
end
