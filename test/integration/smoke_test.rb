require "test_helper"

# Smoke test — pages principales à valider avant chaque push.
# Lance avec : rails test test/integration/smoke_test.rb
#
# Ce test détecte :
#   - Erreurs de syntaxe ERB (SyntaxError → rendu 500)
#   - Variables manquantes dans les controllers (NoMethodError/nil)
#   - Routes cassées (RoutingError → 404 inattendu)
#   - Régressions sur les pages indexées Google
#
# WebMock (configuré dans test_helper) bloque tous les appels API-Football.
# Les controllers retombent sur les fallbacks (nil / []) → on teste le rendu.

class SmokeTest < ActionDispatch::IntegrationTest

  setup do
    # Stub tous les appels API-Football — les controllers retombent sur les fallbacks nil/[]
    WebMock.stub_request(:any, /api-sports\.io/).to_return(
      status: 503,
      body: '{"response":[]}',
      headers: { "Content-Type" => "application/json" }
    )
    Rails.cache.clear
  end

  # --- HOME ---
  test "home page responds 200" do
    get root_url
    assert_response :success, "La home retourne une erreur — vérifier days#show"
  end

  # --- RÉSULTATS ---
  test "resultats page responds 200" do
    get resultats_url
    assert_response :success, "La page résultats retourne une erreur"
  end

  # --- CLASSEMENTS ---
  test "classements index responds 200" do
    get standings_url
    assert_response :success, "La liste des classements retourne une erreur"
  end

  test "classement ligue-1 responds 200" do
    get standing_url("ligue-1")
    assert_response :success, "Le classement Ligue 1 retourne une erreur — vérifier standings/show.html.erb"
  end

  test "classement champions-league responds 200" do
    get standing_url("champions-league")
    assert_response :success, "Le classement Champions League retourne une erreur"
  end

  test "classement premier-league responds 200" do
    get standing_url("premier-league")
    assert_response :success, "Le classement Premier League retourne une erreur"
  end

  test "classement bundesliga responds 200" do
    get standing_url("bundesliga")
    assert_response :success, "Le classement Bundesliga retourne une erreur"
  end

  test "classement slug inexistant retourne 404" do
    get standing_url("slug-qui-nexiste-pas")
    assert_response :not_found, "Un slug classement invalide devrait retourner 404"
  end

  # --- COMPÉTITIONS ---
  test "competitions index responds 200" do
    get competitions_url
    assert_response :success, "La liste des compétitions retourne une erreur"
  end

  test "competition ligue-1 responds 200" do
    get competition_url("ligue-1")
    assert_response :success, "La page compétition Ligue 1 retourne une erreur"
  end

  test "competition champions-league responds 200" do
    get competition_url("champions-league")
    assert_response :success, "La page compétition Champions League retourne une erreur"
  end

  test "competition premier-league responds 200" do
    get competition_url("premier-league")
    assert_response :success, "La page compétition Premier League retourne une erreur"
  end

  # --- ÉQUIPES ---
  test "teams index responds 200" do
    get teams_url
    assert_response :success, "La liste des équipes retourne une erreur"
  end

  test "team avec matchs en DB responds 200" do
    # Utilise le fixture — Paris Saint-Germain est dans matches.yml
    get team_url("paris-saint-germain")
    assert_response :success, "La page équipe PSG retourne une erreur — vérifier teams/show.html.erb"
  end

  test "team slug inexistant retourne 200 avec fallback" do
    # Un slug sans matchs en DB → fallback gracieux, pas de 500
    get team_url("equipe-inconnue-xyz")
    assert_response :success, "Une équipe sans matchs en DB devrait afficher une page vide, pas une erreur"
  end

  # --- MATCHS ---
  test "match a venir responds 200" do
    slug = matches(:upcoming).slug
    get match_url(slug)
    assert_response :success, "Une page match à venir retourne une erreur — vérifier matches/show.html.erb"
  end

  test "match termine responds 200" do
    slug = matches(:finished).slug
    get match_url(slug)
    assert_response :success, "Une page match terminé retourne une erreur — vérifier matches/show.html.erb"
  end

  test "match slug inexistant redirige vers home" do
    get match_url("slug-qui-nexiste-pas")
    assert_response :redirect
  end

  # --- BLOG ---
  test "blog index responds 200" do
    get blog_url
    assert_response :success, "La page blog retourne une erreur"
  end

  # --- PAGES STATIQUES ---
  test "page a-propos responds 200" do
    get a_propos_url
    assert_response :success, "La page à propos retourne une erreur"
  end

  test "page contact responds 200" do
    get contact_url
    assert_response :success, "La page contact retourne une erreur"
  end

  # --- REDIRECTIONS LEGACY (anti-régression SEO) ---
  test "classement numerique redirige en 301" do
    get "/classements/61"
    assert_response :moved_permanently, "La redirection 301 des classements numeriques est cassée"
  end

  test "equipe legacy redirige en 301" do
    get "/equipe/paris-saint-germain"
    assert_response :redirect
  end
end
