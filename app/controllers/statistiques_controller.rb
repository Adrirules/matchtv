class StatistiquesController < ApplicationController
  LEAGUES = [
    { slug: "ligue-1",          id: 61,  name: "Ligue 1",           country: "France" },
    { slug: "premier-league",   id: 39,  name: "Premier League",    country: "Angleterre" },
    { slug: "champions-league", id: 2,   name: "Champions League",  country: "Europe" },
    { slug: "la-liga",          id: 140, name: "La Liga",           country: "Espagne" },
    { slug: "bundesliga",       id: 78,  name: "Bundesliga",        country: "Allemagne" },
    { slug: "serie-a",          id: 135, name: "Serie A",           country: "Italie" },
    { slug: "ligue-2",          id: 62,  name: "Ligue 2",           country: "France" },
    { slug: "europa-league",    id: 3,   name: "Europa League",     country: "Europe" },
  ].freeze

  def top_scorers
    @league = LEAGUES.find { |l| l[:slug] == params[:slug] }
    render "errors/not_found", status: :not_found and return unless @league

    season = FootballApiService::LEAGUE_SEASONS[@league[:id]]
    api = FootballApiService.new
    @players = Rails.cache.fetch("top_scorers_#{@league[:id]}_#{season}", expires_in: 6.hours) do
      api.fetch_top_scorers(@league[:id], season: season)
    end || []

    @page_title = "Meilleurs buteurs #{@league[:name]} #{season}-#{season + 1} | Coup d'Envoi TV"
    @page_desc  = "Classement des meilleurs buteurs de #{@league[:name]} #{season}-#{season + 1} : buts, passes décisives, matchs joués et moyennes de chaque joueur."
    expires_in 6.hours, public: true
  end

  def top_assists
    @league = LEAGUES.find { |l| l[:slug] == params[:slug] }
    render "errors/not_found", status: :not_found and return unless @league

    season = FootballApiService::LEAGUE_SEASONS[@league[:id]]
    api = FootballApiService.new
    @players = Rails.cache.fetch("top_assists_#{@league[:id]}_#{season}", expires_in: 6.hours) do
      response = api.send(:tracked_get, '/players/topassists', { league: @league[:id], season: season })
      response.success? ? JSON.parse(response.body)['response'] || [] : []
    end || []

    @page_title = "Meilleurs passeurs #{@league[:name]} #{season}-#{season + 1} | Coup d'Envoi TV"
    @page_desc  = "Classement des meilleurs passeurs de #{@league[:name]} #{season}-#{season + 1} : passes décisives, buts, matchs joués."
    expires_in 6.hours, public: true
  end
end
