class FootballApiService
  BASE_URL = 'https://v3.football.api-sports.io'

  def initialize
    @api_key = ENV['FOOTBALL_API_KEY']
  end

  def test_connection
    response = client.get('/leagues', { country: 'France', name: 'Ligue 1' })

    if response.success?
      JSON.parse(response.body)
    else
      { error: "Échec : #{response.status}", message: response.body }
    end
  end

  def fetch_fixtures(date)
    # On appelle l'endpoint /fixtures
    # league: 61 (Ligue 1), season: 2025 (à ajuster selon la saison en cours)
    response = client.get('/fixtures', {
      league: 61,
      season: 2025,
      date: date.strftime('%Y-%m-%d')
    })

    if response.success?
      JSON.parse(response.body)['response']
    else
      []
    end
  end
  def fetch_upcoming
    # L'argument 'next: 10' demande les 10 prochains matchs à venir
    response = client.get('/fixtures', {
      league: 61,
      season: 2025,
      next: 10
    })

    if response.success?
      JSON.parse(response.body)['response']
    else
      []
    end
  end
  def check_seasons
    response = client.get('/leagues', { id: 61 })
    JSON.parse(response.body)['response']
  end


  def fetch_all_remaining_fixtures
    # On demande la saison 2023 car c'est la seule accessible en gratuit
    response = client.get('/fixtures', {
      league: 61,
      season: 2023
    })
    JSON.parse(response.body)['response'] || []
  end

  def import_upcoming_fixtures(league_id: 61, season: 2025)
    # 1. On récupère les matchs (le plan PRO permet de voir loin)
    # On peut filtrer par 'status: NS' (Not Started) pour ne pas gâcher de requêtes
    response = client.get('/fixtures', {
      league: league_id,
      season: season,
      from: Date.today.strftime('%Y-%m-%d'),
      to: (Date.today + 30.days).strftime('%Y-%m-%d') # On anticipe sur 1 mois !
    })

    fixtures = JSON.parse(response.body)['response'] || []
    return "Aucun match trouvé" if fixtures.empty?

    fixtures.each do |data|
      home_name = data['teams']['home']['name']
      away_name = data['teams']['away']['name']

      # On crée un slug unique pour le match (SEO)
      # ex: "2026-02-15-psg-marseille"
      match_date = DateTime.parse(data['fixture']['date']).to_date
      match_slug = "#{match_date}-#{home_name.parameterize}-#{away_name.parameterize}"

      matchup_slug = "#{home_name.parameterize}-#{away_name.parameterize}"
      matchup = Matchup.find_or_create_by!(slug: matchup_slug)

      match = Match.find_or_initialize_by(api_id: data['fixture']['id'])

      match.update!(
        matchup: matchup,
        home_team: home_name,
        away_team: away_name,
        home_team_logo: data['teams']['home']['logo'],
        away_team_logo: data['teams']['away']['logo'],
        start_time: DateTime.parse(data['fixture']['date']), # PLUS DE +2 YEARS !
        competition: data['league']['name'],
        # On essaie de choper les chaînes si l'API les donne (dépend des pays)
        tv_channels: data['fixture']['venue']['name'] || "À définir",
        api_id: data['fixture']['id'],
        slug: match_slug # Très important pour tes routes
      )
    end
    "Import terminé : #{fixtures.count} matchs synchronisés pour 2026 !"
  end

  def get_standings(league_id)
    # Mise en cache pour 2h (Expertise Performance)
    Rails.cache.fetch("standings_league_#{league_id}", expires_in: 2.hours) do
      # On utilise ton client Faraday déjà prêt
      response = client.get('/standings', { league: league_id, season: 2025 })

      if response.success?
        JSON.parse(response.body)['response']
      else
        []
      end
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
