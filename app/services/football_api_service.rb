class FootballApiService
  BASE_URL = 'https://v3.football.api-sports.io'

  # Liste des compétitions à synchroniser (Tu peux en ajouter ici)
  # Format: { id_api => "Nom Propre" }
  SUPPORTED_LEAGUES = {
    61  => "Ligue 1",
    62  => "Ligue 2",
    39  => "Premier League",
    140 => "La Liga",
    78  => "Bundesliga",
    135 => "Serie A",
    2   => "Champions League",
    3   => "Europa League",
    141 => "Coupe du Roi"
  }

  def initialize
    @api_key = ENV['FOOTBALL_API_KEY']
  end

  # --- LOGIQUE DE MAPPING DES DIFFUSEURS (Le secret pour éviter la fausse info) ---
  def guess_tv_channel(league_id, start_time)
    case league_id
    when 61 # Ligue 1
      # On affine selon le créneau horaire (Mapping LFP classique)
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
    when 39 # Premier League
      "Canal+"
    when 140, 78, 135 # Liga, Bundesliga, Serie A
      "beIN Sports"
    when 2, 3 # Coupes d'Europe
      "Canal+ / Canal+ Foot"
    when 193, 194, 202 # D1 Féminine ou coupes
      "Canal+ Foot"
    else
      "À confirmer"
    end
  end

  def import_upcoming_fixtures(league_id: 61, season: 2025)
    # 1. On récupère les matchs sur une fenêtre de 30 jours
    response = client.get('/fixtures', {
      league: league_id,
      season: season,
      from: Date.today.strftime('%Y-%m-%d'),
      to: (Date.today + 30.days).strftime('%Y-%m-%d')
    })

    fixtures = JSON.parse(response.body)['response'] || []
    return "Aucun match trouvé pour la ligue #{league_id}" if fixtures.empty?

    fixtures.each do |data|
      home_name = data['teams']['home']['name']
      away_name = data['teams']['away']['name']
      match_date_time = DateTime.parse(data['fixture']['date'])
      match_date = match_date_time.to_date

      # SEO Slug
      match_slug = "#{match_date}-#{home_name.parameterize}-#{away_name.parameterize}"

      # Gestion du Matchup (Relation 1-N)
      matchup_slug = "#{home_name.parameterize}-#{away_name.parameterize}"
      matchup = Matchup.find_or_create_by!(slug: matchup_slug)

      # Création ou Mise à jour du Match
      match = Match.find_or_initialize_by(api_id: data['fixture']['id'])

      # --- UTILISATION DU MAPPING INTELLIGENT ---
      # On n'utilise plus data['fixture']['venue']['name']
      precise_tv = guess_tv_channel(league_id, match_date_time)

      match.update!(
        matchup: matchup,
        home_team: home_name,
        away_team: away_name,
        home_team_logo: data['teams']['home']['logo'],
        away_team_logo: data['teams']['away']['logo'],
        start_time: match_date_time,
        competition: data['league']['name'],
        tv_channels: precise_tv, # <--- C'est ici que la magie opère !
        api_id: data['fixture']['id'],
        slug: match_slug
      )
    end
    "Import terminé : #{fixtures.count} matchs synchronisés pour la ligue #{league_id} !"
  end

  # --- METHODES DE DIAGNOSTIC / TESTS ---

  def test_connection
    response = client.get('/leagues', { country: 'France', name: 'Ligue 1' })
    response.success? ? JSON.parse(response.body) : { error: response.status }
  end

  def get_standings(league_id)
    Rails.cache.fetch("standings_league_#{league_id}", expires_in: 2.hours) do
      response = client.get('/standings', { league: league_id, season: 2025 })
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
