class WorldCupController < ApplicationController
  GROUPS = YAML.load_file(Rails.root.join('config', 'cdm_2026_groups.yml')).freeze

  TOURNAMENT_START = Date.new(2026, 6, 11).freeze
  TOURNAMENT_END   = Date.new(2026, 7, 19).freeze

  def group
    letter = params[:letter].upcase
    @group_data = GROUPS[letter]
    return render "errors/not_found", status: :not_found unless @group_data

    @letter = letter

    # Standings depuis la DB (synchés daily)
    standing = Standing.for_league(1)
    all_groups = standing&.data&.dig(0, "league", "standings") || []
    group_index = letter.ord - 'A'.ord
    @standings_rows = all_groups[group_index] || []

    # Matchs du groupe depuis la DB
    api_names = @group_data["teams_api"]
    @matches = Match.where(competition: "Coupe du Monde 2026")
                    .where("round ILIKE ?", "%Group%")
                    .where("home_team IN (?) OR away_team IN (?)", api_names, api_names)
                    .order(:start_time)

    @tournament_started = Date.today >= TOURNAMENT_START

    @page_title = "#{@group_data["label"]} Coupe du Monde 2026 — Classement et matchs | Coup d'Envoi TV"
    @page_desc  = "Classement en direct et programme du #{@group_data["label"]} du Mondial 2026 : #{@group_data["teams_fr"].join(", ")}."
    expires_in 30.minutes, public: true
  end

  def top_scorers
    @scorers = Rails.cache.fetch("cdm_2026_top_scorers", expires_in: 6.hours) do
      FootballApiService.new.fetch_top_scorers(1, season: 2026)
    end || []

    @tournament_started = Date.today >= TOURNAMENT_START

    @page_title = "Meilleurs buteurs Coupe du Monde 2026 — Classement live | Coup d'Envoi TV"
    @page_desc  = "Le classement des meilleurs buteurs de la Coupe du Monde 2026 en temps réel. Qui sera le Golden Boot du Mondial 2026 ?"
    expires_in 1.hour, public: true
  end
end
