class WeatherService
  BASE_URL = "https://api.open-meteo.com/v1/forecast".freeze

  COORDINATES = begin
    YAML.load_file(Rails.root.join("config", "team_coordinates.yml")) || {}
  rescue
    {}
  end

  # WMO Weather Interpretation Codes → description française courte
  WEATHER_LABELS = {
    0  => "ciel dégagé",
    1  => "peu nuageux",
    2  => "partiellement nuageux",
    3  => "couvert",
    45 => "brouillard",
    48 => "brouillard givrant",
    51 => "bruine légère",
    53 => "bruine",
    55 => "bruine dense",
    61 => "pluie légère",
    63 => "pluie",
    65 => "pluie forte",
    71 => "neige légère",
    73 => "neige",
    75 => "neige forte",
    77 => "grains de neige",
    80 => "averses légères",
    81 => "averses",
    82 => "averses violentes",
    85 => "averses de neige",
    86 => "averses de neige fortes",
    95 => "orage",
    96 => "orage avec grêle",
    99 => "orage violent"
  }.freeze

  # Retourne une phrase météo pour le match, ou nil si pas de données
  # Ex: "Météo à Paris ce soir : 12°C, pluie légère, vent 22 km/h"
  def self.for_match(match)
    coords = COORDINATES[match.home_team]
    return nil unless coords

    fetch(
      lat:        coords["lat"],
      lon:        coords["lon"],
      city:       coords["city"],
      start_time: match.start_time
    )
  rescue => e
    Rails.logger.warn("[WeatherService] Erreur pour #{match.home_team}: #{e.message}")
    nil
  end

  private

  def self.fetch(lat:, lon:, city:, start_time:)
    date = start_time.in_time_zone("Paris").to_date
    hour = start_time.in_time_zone("Paris").hour

    conn = Faraday.new do |f|
      f.response :json
    end

    resp = conn.get(BASE_URL, {
      latitude:       lat,
      longitude:      lon,
      hourly:         "temperature_2m,weathercode,windspeed_10m",
      timezone:       "Europe/Paris",
      start_date:     date.to_s,
      end_date:       date.to_s
    })

    return nil unless resp.success?

    data    = resp.body
    hours   = data.dig("hourly", "time") || []
    temps   = data.dig("hourly", "temperature_2m") || []
    codes   = data.dig("hourly", "weathercode") || []
    winds   = data.dig("hourly", "windspeed_10m") || []

    idx = hours.index { |t| t.end_with?("T#{hour.to_s.rjust(2, '0')}:00") }
    return nil unless idx

    temp  = temps[idx]&.round
    code  = codes[idx]&.to_i
    wind  = winds[idx]&.round
    label = WEATHER_LABELS[code] || WEATHER_LABELS.min_by { |k, _| (k - code).abs }&.last

    return nil if temp.nil?

    parts = ["#{temp}°C", label].compact
    parts << "vent #{wind} km/h" if wind && wind >= 20

    "Météo à #{city} au coup d'envoi : #{parts.join(', ')}."
  end
end
