class StandingsController < ApplicationController

  LEAGUES = [
    { id: 61,  slug: "ligue-1",            name: "Ligue 1",            country: "France" },
    { id: 2,   slug: "champions-league",   name: "Champions League",   country: "Europe" },
    { id: 39,  slug: "premier-league",     name: "Premier League",     country: "Angleterre" },
    { id: 62,  slug: "ligue-2",            name: "Ligue 2",            country: "France" },
    { id: 140, slug: "la-liga",            name: "La Liga",            country: "Espagne" },
    { id: 3,   slug: "europa-league",      name: "Europa League",      country: "Europe" },
    { id: 78,  slug: "bundesliga",         name: "Bundesliga",         country: "Allemagne" },
    { id: 135, slug: "serie-a",            name: "Serie A",            country: "Italie" },
    { id: 848, slug: "conference-league",  name: "Conference League",  country: "Europe" },
    { id: 63,  slug: "national",           name: "National",           country: "France" },
    { id: 307, slug: "saudi-pro-league",   name: "Saudi Pro League",   country: "Arabie Saoudite" },
    { id: 193, slug: "d1-feminine",        name: "D1 Féminine",        country: "France" },
    { id: 88,  slug: "eredivisie",         name: "Eredivisie",         country: "Pays-Bas" },
    { id: 94,  slug: "liga-portugal",      name: "Liga Portugal",      country: "Portugal" },
  ].freeze

  SLUG_TO_ID = LEAGUES.index_by { |l| l[:slug] }.transform_values { |l| l[:id] }.freeze
  ID_TO_SLUG = LEAGUES.index_by { |l| l[:id] }.transform_values { |l| l[:slug] }.freeze

  before_action :redirect_numeric_id, only: :show

  def index
    @leagues = LEAGUES.map do |l|
      l.merge(logo: "https://media.api-sports.io/football/leagues/#{l[:id]}.png")
    end
    @page_title = "Classements Football 2025-2026 — Ligue 1, Champions League, Premier League | Coup d'Envoi TV"
    @page_desc  = "Consultez les classements complets de tous les championnats de football 2025-2026 : Ligue 1, Champions League, Premier League, Ligue 2, La Liga, Bundesliga et plus."
    expires_in 6.hours, public: true
  end

  def show
    slug = params[:competition_id]
    league_id = SLUG_TO_ID[slug]

    unless league_id
      render "errors/not_found", status: :not_found and return
    end

    @league_info = LEAGUES.find { |l| l[:id] == league_id }
    api_data     = FootballApiService.new.get_standings(league_id)

    if api_data.present? && api_data[0]
      @league_name = api_data[0]["league"]["name"]
      @league_logo = api_data[0]["league"]["logo"]
      raw_standings = api_data[0]["league"]["standings"]
      # Certaines ligues (UCL, UEL) ont plusieurs groupes
      @groups = raw_standings.length > 1 ? raw_standings : nil
      @standings = raw_standings[0]
    else
      @standings = []
    end

    @page_title = "Classement #{@league_name || @league_info[:name]} 2025-2026 | Coup d'Envoi TV"
    @page_desc  = "Classement officiel #{@league_name || @league_info[:name]} 2025-2026 mis à jour en temps réel : points, victoires, défaites, différence de buts de toutes les équipes."

    expires_in 6.hours, public: true
  end

  private

  def redirect_numeric_id
    if params[:competition_id] =~ /\A\d+\z/
      slug = ID_TO_SLUG[params[:competition_id].to_i]
      if slug
        redirect_to standing_path(slug), status: :moved_permanently
      else
        render "errors/not_found", status: :not_found
      end
    end
  end
end
