class FootballApiService
  BASE_URL = 'https://v3.football.api-sports.io'

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
    when 62, 140, 78, 135, 141, 203, 307 # beIN Sports Pack
      "beIN Sports"
    when 39 # Premier League
      "Canal+"
    when 2, 3, 848, 193 # Canal+ Pack (Europe & D1F)
      "Canal+ / Canal+ Foot"
    when 529 # Coupe de France
      "France TV / beIN Sports"
    when 63 # National
      "FFF tv / Canal+ Foot"
    else
      "À confirmer"
    end
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

  def get_standings(league_id, season: 2025)
    Rails.cache.fetch("standings_league_#{league_id}", expires_in: 2.hours) do
      response = client.get('/standings', { league: league_id, season: season })
      response.success? ? JSON.parse(response.body)['response'] : []
    end
  end

  private

  def client
    @client ||= Faraday.new(url: BASE_URL) do |config|
      config.headers['x-apisports-key'] = @api_key
      config.headers['Content-Type'] = 'application/json'
      config.adapter Faraday.default_adapter
    end
  end
end
