# Charge l'environnement Rails
require_relative 'config/environment'
require 'httparty'

# --- CONFIGURATION ---
# Remplace par ta vraie clé API-Football
API_KEY = "TA_CLE_API_ICI"
# ---------------------

def test_broadcasters
  url = "https://v3.football.api-sports.io/fixtures"
  # On teste sur les matchs d'aujourd'hui
  date = Time.current.strftime("%Y-%m-%d")

  puts "🛰️  Interrogation de l'API pour la date : #{date}..."

  headers = {
    "x-rapidapi-key" => API_KEY,
    "x-rapidapi-host" => "v3.football.api-sports.io"
  }

  response = HTTParty.get(url, query: { date: date }, headers: headers)

  if response.code != 200
    puts "❌ Erreur API : #{response.code} - #{response.message}"
    return
  end

  fixtures = response.parsed_response["response"]

  if fixtures.nil? || fixtures.empty?
    puts "ℹ️ Aucun match trouvé pour cette date."
    return
  end

  puts "🔍 Analyse de #{fixtures.count} matchs..."
  puts "--------------------------------------------------"

  found_count = 0
  fixtures.first(20).each do |f| # On check les 20 premiers pour pas flooder
    home = f["teams"]["home"]["name"]
    away = f["teams"]["away"]["name"]
    league = f["league"]["name"]

    # Extraction des diffuseurs
    broadcasters = f["fixture"]["broadcasters"]

    if broadcasters && broadcasters.any?
      names = broadcasters.map { |b| b["name"] }.join(", ")
      puts "✅ #{league} : #{home} vs #{away}"
      puts "   📺 DIFFUSEUR(S) : #{names}"
      found_count += 1
    else
      puts "❌ #{league} : #{home} vs #{away} -> Aucune chaîne trouvée."
    end
  end

  puts "--------------------------------------------------"
  puts "📊 Résultat : #{found_count} matchs avec chaînes sur les 20 premiers analysés."

  if found_count == 0
    puts "💡 Constat : L'API ne renvoie pas les chaînes pour ton plan actuel ou cette zone géographique."
  else
    puts "🚀 L'API renvoie des infos ! On va pouvoir automatiser ça."
  end
end

test_broadcasters
