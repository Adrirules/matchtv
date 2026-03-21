class FootballApiService
  BASE_URL = 'https://v3.football.api-sports.io'

  # Source de vérité unique — ordre par popularité en France
  COMPETITIONS_META = [
    { id: 61,  name: "Ligue 1",            country: "France",          has_standings: true  },
    { id: 2,   name: "Champions League",   country: "Europe",          has_standings: true  },
    { id: 39,  name: "Premier League",     country: "Angleterre",      has_standings: true  },
    { id: 62,  name: "Ligue 2",            country: "France",          has_standings: true  },
    { id: 529, name: "Coupe de France",    country: "France",          has_standings: false },
    { id: 3,   name: "Europa League",      country: "Europe",          has_standings: true  },
    { id: 140, name: "La Liga",            country: "Espagne",         has_standings: true  },
    { id: 78,  name: "Bundesliga",         country: "Allemagne",       has_standings: true  },
    { id: 135, name: "Serie A",            country: "Italie",          has_standings: true  },
    { id: 848, name: "Conference League",  country: "Europe",          has_standings: true  },
    { id: 63,  name: "National",           country: "France",          has_standings: true  },
    { id: 203, name: "Süper Lig",          country: "Turquie",         has_standings: true  },
    { id: 307, name: "Saudi Pro League",   country: "Arabie Saoudite", has_standings: true  },
    { id: 193, name: "D1 Féminine",        country: "France",          has_standings: true  },
    { id: 88,  name: "Eredivisie",         country: "Pays-Bas",        has_standings: true  },
    { id: 94,  name: "Liga Portugal",      country: "Portugal",        has_standings: true  },
    { id: 141, name: "Coupe du Roi",       country: "Espagne",         has_standings: false },
    { id: 253, name: "Major League Soccer",country: "USA",             has_standings: true  },
    { id: 5,   name: "Qualif. Mondial 2026", country: "Europe",        has_standings: false },
    { id: 4,   name: "Euro / Nations League", country: "Europe",       has_standings: false },
    { id: 9,   name: "Copa America",       country: "Amérique du Sud", has_standings: false },
  ].freeze

  # Helper : logo officiel depuis l'API Sports CDN
  def self.league_logo(id)
    "https://media.api-sports.io/football/leagues/#{id}.png"
  end

  # Liste exhaustive des 20 ligues (Pack Foot Mercato + Arabie Saoudite + Coupes)
  SUPPORTED_LEAGUES = {
    61  => "Ligue 1",
    62  => "Ligue 2",
    63  => "National",
    39  => "Premier League",
    140 => "La Liga",
    78  => "Bundesliga",
    135 => "Serie A",
    2   => "Champions League",
    3   => "Europa League",
    848 => "Conference League",
    193 => "D1 Féminine",
    141 => "Coupe du Roi",
    529 => "Coupe de France",
    88  => "Eredivisie",
    94  => "Liga Portugal",
    203 => "Süper Lig",
    307 => "Saudi Pro League",
    253 => "Major League Soccer",
    5   => "Qualif. Mondial 2026",
    4   => "Euro / Nations League",
    9   => "Copa America"
  }

  def initialize
    @api_key = ENV['FOOTBALL_API_KEY']
  end

  # --- LOGIQUE DE MAPPING DES DIFFUSEURS (Expertise SEO & Précision) ---
  def guess_tv_channel(league_id, start_time)
    case league_id
    when 61 # Ligue 1
      if start_time.strftime("%A %H:%M") == "Sunday 20:45"
        "DAZN 1 (Top Match)"
      elsif start_time.strftime("%A %H:%M") == "Sunday 17:00"
        "DAZN (Multiplex)"
      elsif start_time.strftime("%A %H:%M") == "Saturday 17:00"
        "beIN Sports 1"
      else
        "DAZN"
      end
    when 62 # Ligue 2
      "beIN Sports"
    when 63 # National
      "Canal+ Foot"
    when 39 # Premier League
      "Canal+"
    when 140 # La Liga
      "beIN Sports"
    when 78 # Bundesliga
      "beIN Sports"
    when 135 # Serie A
      "beIN Sports"
    when 141 # Coupe du Roi
      "beIN Sports"
    when 2 # Champions League
      "Canal+"
    when 3 # Europa League
      "Canal+ / beIN Sports"
    when 848 # Conference League
      "Canal+"
    when 193 # D1 Féminine
      "Canal+ Foot"
    when 529 # Coupe de France
      "France TV / beIN Sports"
    when 88 # Eredivisie
      "DAZN"
    when 94 # Liga Portugal
      "Canal+ Foot"
    when 203 # MLS
      "Apple TV+"
    when 307 # Saudi Pro League
      "beIN Sports"
    when 5 # Qualif. Mondial 2026
      "TF1 / M6"
    when 4 # Euro / Nations League
      "TF1 / M6"
    when 9 # Copa America
      "beIN Sports"
    else
      "À confirmer"
    end
  end

  def import_historical_fixtures(league_id:, season: 2025, from_date:, to_date:)
    response = client.get('/fixtures', {
      league:  league_id,
      season:  season,
      from:    from_date.strftime('%Y-%m-%d'),
      to:      to_date.strftime('%Y-%m-%d')
    })

    fixtures = JSON.parse(response.body)['response'] || []
    return "Aucun match trouvé pour ligue #{league_id}" if fixtures.empty?

    fixtures.each do |data|
      home_name      = data['teams']['home']['name']
      away_name      = data['teams']['away']['name']
      match_date_time = DateTime.parse(data['fixture']['date'])
      match_date     = match_date_time.to_date
      match_slug     = "#{match_date}-#{home_name.parameterize}-#{away_name.parameterize}"
      matchup_slug   = "#{home_name.parameterize}-#{away_name.parameterize}"
      matchup        = Matchup.find_or_create_by!(slug: matchup_slug)
      match          = Match.find_or_initialize_by(api_id: data['fixture']['id'])

      match.update!(
        matchup:           matchup,
        home_team:         home_name,
        away_team:         away_name,
        home_team_logo:    data['teams']['home']['logo'],
        away_team_logo:    data['teams']['away']['logo'],
        home_team_api_id:  data['teams']['home']['id'],
        away_team_api_id:  data['teams']['away']['id'],
        start_time:        match_date_time,
        competition:       SUPPORTED_LEAGUES[league_id] || data['league']['name'],
        tv_channels:       guess_tv_channel(league_id, match_date_time),
        api_id:            data['fixture']['id'],
        slug:              match_slug
      )

      # Mise à jour score + statut pour les matchs terminés
      update_match_from_data(data, match)
    end

    "#{fixtures.count} matchs importés pour #{SUPPORTED_LEAGUES[league_id]}"
  end

  def import_upcoming_fixtures(league_id: 61, season: 2025)
    # On récupère les matchs sur une fenêtre de 30 jours
    response = client.get('/fixtures', {
      league: league_id,
      season: season,
      from: Date.today.strftime('%Y-%m-%d'),
      to: (Date.today + 30.days).strftime('%Y-%m-%d')
    })

    fixtures = JSON.parse(response.body)['response'] || []

    # Sécurité : Si 2025 ne renvoie rien, on peut tenter 2024 (pour les ligues décalées)
    if fixtures.empty? && season == 2025
      return import_upcoming_fixtures(league_id: league_id, season: 2024)
    end

    return "Aucun match trouvé pour la ligue #{league_id}" if fixtures.empty?

    fixtures.each do |data|
      home_name = data['teams']['home']['name']
      away_name = data['teams']['away']['name']
      match_date_time = DateTime.parse(data['fixture']['date'])
      match_date = match_date_time.to_date

      # SEO Slug (ex: 2026-02-15-psg-marseille)
      match_slug = "#{match_date}-#{home_name.parameterize}-#{away_name.parameterize}"

      # Gestion du Matchup (Relation 1-N pour l'historique)
      matchup_slug = "#{home_name.parameterize}-#{away_name.parameterize}"
      matchup = Matchup.find_or_create_by!(slug: matchup_slug)

      # Création ou Mise à jour
      match = Match.find_or_initialize_by(api_id: data['fixture']['id'])

      # Utilisation du Mapping Intelligent pour tv_channels
      precise_tv = guess_tv_channel(league_id, match_date_time)

      match.update!(
        matchup: matchup,
        home_team: home_name,
        away_team: away_name,
        home_team_logo: data['teams']['home']['logo'],
        away_team_logo: data['teams']['away']['logo'],
        home_team_api_id: data['teams']['home']['id'],
        away_team_api_id: data['teams']['away']['id'],
        start_time: match_date_time,
        competition: SUPPORTED_LEAGUES[league_id] || data['league']['name'],
        tv_channels: precise_tv,
        api_id: data['fixture']['id'],
        slug: match_slug
      )
    end
    "Import terminé : #{fixtures.count} matchs pour #{SUPPORTED_LEAGUES[league_id]}"
  end

  # --- DIAGNOSTIC & STANDINGS ---

  def test_connection
    response = client.get('/leagues', { country: 'France', name: 'Ligue 1' })
    response.success? ? JSON.parse(response.body) : { error: response.status }
  end

  # --- LIVE SCORES ---

  def fetch_live_scores
    fixtures = get_fixtures(live: 'all')
    api_ids  = fixtures.map { |f| f['fixture']['id'] }

    fixtures.each { |data| update_match_from_data(data) }

    # Matchs qui étaient live mais ne le sont plus → score final
    Match.where(status: Match::LIVE_STATUSES).where.not(api_id: api_ids)
         .find_each { |m| fetch_fixture_result(m.api_id) }
  end

  def fetch_date_results(date)
    fixtures = get_fixtures(date: date.strftime('%Y-%m-%d'), status: 'FT-AET-PEN-1H-HT-2H-ET-BT-P')
    fixtures.each { |data| update_match_from_data(data) }
  end

  def fetch_today_results
    fetch_date_results(Date.today)
  end

  def fetch_fixture_events(fixture_id)
    response = client.get('/fixtures/events', { fixture: fixture_id })
    return [] unless response.success?
    JSON.parse(response.body)['response'] || []
  end

  def fetch_fixture_result(api_id)
    response = client.get('/fixtures', { id: api_id })
    return unless response.success?
    data  = JSON.parse(response.body)['response']&.first
    match = Match.find_by(api_id: api_id)
    return unless data && match
    update_match_from_data(data, match)
    match
  end

  def fetch_squad(team_api_id)
    Rails.cache.fetch("squad_#{team_api_id}", expires_in: 24.hours) do
      response = client.get('/players/squads', { team: team_api_id })
      return [] unless response.success?
      JSON.parse(response.body).dig('response', 0, 'players') || []
    end
  end

  def fetch_player_stats(player_api_id, season: 2025)
    Rails.cache.fetch("player_stats_#{player_api_id}_#{season}", expires_in: 6.hours) do
      response = client.get('/players', { id: player_api_id, season: season })
      return nil unless response.success?
      JSON.parse(response.body).dig('response', 0)
    end
  end

  def fetch_team_stats(team_api_id, league_id, season: 2025)
    Rails.cache.fetch("team_stats_#{team_api_id}_#{league_id}_#{season}", expires_in: 6.hours) do
      response = client.get('/teams/statistics', { team: team_api_id, league: league_id, season: season })
      return nil unless response.success?
      result = JSON.parse(response.body)['response']
      result.is_a?(Hash) ? result : nil
    end
  end

  def fetch_recent_results(team_api_id, count: 5)
    Rails.cache.fetch("team_recent_#{team_api_id}_#{count}", expires_in: 1.hour) do
      response = client.get('/fixtures', { team: team_api_id, last: count, status: 'FT-AET-PEN' })
      return [] unless response.success?
      JSON.parse(response.body)['response'] || []
    end
  end

  def get_standings(league_id, season: 2025)
    Rails.cache.fetch("standings_league_#{league_id}", expires_in: 2.hours) do
      response = client.get('/standings', { league: league_id, season: season })
      response.success? ? JSON.parse(response.body)['response'] : []
    end
  end

  def fetch_top_scorers(league_id, season: 2025)
    Rails.cache.fetch("top_scorers_#{league_id}_#{season}", expires_in: 6.hours) do
      response = client.get('/players/topscorers', { league: league_id, season: season })
      return [] unless response.success?
      JSON.parse(response.body)['response'] || []
    end
  end

  def fetch_coach(team_api_id)
    Rails.cache.fetch("coach_#{team_api_id}", expires_in: 7.days) do
      response = client.get('/coachs', { team: team_api_id })
      return nil unless response.success?
      JSON.parse(response.body)['response']&.first
    end
  end

  def fetch_head_to_head(home_id, away_id, count: 5)
    Rails.cache.fetch("h2h_#{home_id}_#{away_id}", expires_in: 7.days) do
      response = client.get('/fixtures/headtohead', { h2h: "#{home_id}-#{away_id}", last: count })
      return [] unless response.success?
      JSON.parse(response.body)['response'] || []
    end
  end

  def fetch_injuries(fixture_id)
    Rails.cache.fetch("injuries_#{fixture_id}", expires_in: 6.hours) do
      response = client.get('/injuries', { fixture: fixture_id })
      return [] unless response.success?
      JSON.parse(response.body)['response'] || []
    end
  end

  private

  def get_fixtures(params)
    response = client.get('/fixtures', params)
    return [] unless response.success?
    JSON.parse(response.body)['response'] || []
  end

  def update_match_from_data(data, match = nil)
    match ||= Match.find_by(api_id: data['fixture']['id'])
    return unless match
    match.update_columns(
      status:     data['fixture']['status']['short'],
      elapsed:    data['fixture']['status']['elapsed'],
      home_score: data['goals']['home'],
      away_score: data['goals']['away'],
      updated_at: Time.current
    )
  end

  def client
    @client ||= Faraday.new(url: BASE_URL) do |config|
      config.headers['x-apisports-key'] = @api_key
      config.headers['Content-Type'] = 'application/json'
      config.adapter Faraday.default_adapter
    end
  end
end
