class StandingsController < ApplicationController
  def index
    # On récupère les noms uniques des compétitions que tu as VRAIMENT en base
    db_competitions = Match.distinct.pluck(:competition).compact

    # Dictionnaire de correspondance (Nom BDD => ID API)
    # C'est la seule partie "manuelle", car l'API ne lie pas les noms string aux IDs facilement
    mapping = {
      "Ligue 1" => 61,
      "Premier League" => 39,
      "La Liga" => 140,
      "Bundesliga" => 78,
      "Serie A" => 135,
      "Champions League" => 2,
      "Europa League" => 3
    }

    @leagues = db_competitions.map do |name|
      league_id = mapping[name]
      next unless league_id # On ignore si on n'a pas l'ID de classement

      {
        id: league_id,
        name: name,
        # On récupère le logo d'un match existant pour ne pas appeler l'API ici
        logo: Match.where(competition: name).first&.home_team_logo || "https://media.api-sports.io/football/leagues/#{league_id}.png"
      }
    end.compact

    @page_title = "Classements Championnats Football - Match TV"
  end

  def show
    @league_id = params[:competition_id]

    # Appel du service (qui gère le cache tout seul)
    api_data = FootballApiService.new.get_standings(@league_id)

    # On extrait les données du JSON
    if api_data.present? && api_data[0]
      @league_name = api_data[0]["league"]["name"]
      @standings = api_data[0]["league"]["standings"][0] # C'est un tableau de rangs
    else
      @standings = []
    end
  end
end
