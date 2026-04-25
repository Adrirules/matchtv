Rails.application.routes.draw do
  root to: "days#show"
  post '/share-click', to: 'share_clicks#create'

  # API SEO — utilisé par la Routine Claude
  get  '/api/seo/fetch-data',      to: 'seo_api#fetch_data'
  post '/api/seo/send-report',     to: 'seo_api#send_report'
  post '/api/seo/send-editorial',  to: 'seo_api#send_editorial'
  get  '/api/seo/history',         to: 'seo_api#history'
  # PRIORITÉ N°1 : Le sitemap (format XML forcé)
  get "sitemap.xml", to: "sitemaps#index", defaults: { format: "xml" }
  # 2. Les jours
  get "days/:date", to: "days#show", as: :day

  # Résultats
  get "resultats", to: "results#show", as: :resultats
  get "resultats/:date", to: "results#show", as: :resultat_date

  # 3. Équipes
  # Redirection automatique de l'ancien vers le nouveau (SEO 301)
  get '/equipe/:team_slug', to: redirect('/equipes/%{team_slug}')
  get  "equipes",                 to: "teams#index", as: :teams
  post "equipes/:team_slug/vote", to: "teams#vote",  as: :vote_team
  get  "equipes/:team_slug",      to: "teams#show",  as: :team

  # 4. Joueurs
  get "joueurs", to: "players#index", as: :players
  get "joueurs/:slug", to: "players#show", as: :player

  # 5. Compétitions
  get "competitions", to: "competitions#index", as: :competitions
  get "competitions/:slug", to: "competitions#show", as: :competition

  # 5. Classements
  get "classement", to: "standings#index"
  get "classements", to: "standings#index", as: :standings
  get "classements/:competition_id/buteurs", to: "standings#top_scorers", as: :top_scorers
  get "classements/:competition_id", to: "standings#show", as: :standing

  # 6. Blog éditorial
  get 'blog', to: 'blog#index', as: :blog
  get 'blog.rss', to: 'blog#feed', as: :blog_feed
  get 'blog/auteur/adrien', to: 'blog#auteur', as: :blog_auteur
  get 'blog/tag/:tag', to: 'blog#tag', as: :blog_tag
  get 'blog/:slug', to: 'blog#show', as: :blog_article

  # 7. Chaînes TV
  get "chaines",       to: "channels#index", as: :channels
  get "chaines/:slug", to: "channels#show",  as: :channel

  # 8. Pages Statiques
  get "contact", to: "pages#contact", as: :contact
  get "a-propos", to: "pages#about", as: :a_propos
  get "mentions-legales", to: "pages#legal", as: :mentions_legales
  get "politique-de-confidentialite", to: "pages#privacy", as: :politique_confidentialite
  get "archives",        to: "pages#archives",  as: :archives
  get "nous-soutenir",   to: "pages#soutenir",  as: :nous_soutenir

  # 7. MATCHS (EN DERNIER)
  # On le met en dernier pour qu'il ne "vole" pas les URLs des autres pages
  resources :matches, only: [:show], param: :slug do
    member do
      get :live_score
    end
  end

  # Redirections 301 — ancien pluriel français /matchs/ → /matches/
  get '/matchs/:slug', to: redirect('/matches/%{slug}')

  # Redirections 301 — anciennes URLs /ligue/* indexées par Google
  get '/ligues',                        to: redirect('/competitions')
  get '/ligue/ligue-1',                 to: redirect('/competitions/ligue-1')
  get '/ligue/ligue-2',                 to: redirect('/competitions/ligue-2')
  get '/ligue/national',                to: redirect('/competitions/national')
  get '/ligue/champions-league',        to: redirect('/competitions/champions-league')
  get '/ligue/uefa-champions-league',   to: redirect('/competitions/champions-league')
  get '/ligue/premier-league',          to: redirect('/competitions/premier-league')
  get '/ligue/la-liga',                 to: redirect('/competitions/la-liga')
  get '/ligue/bundesliga',              to: redirect('/competitions/bundesliga')
  get '/ligue/serie-a',                 to: redirect('/competitions/serie-a')
  get '/ligue/europa-league',           to: redirect('/competitions/europa-league')
  get '/ligue/uefa-europa-league',      to: redirect('/competitions/europa-league')
  get '/ligue/conference-league',       to: redirect('/competitions/conference-league')
  get '/ligue/super-lig',               to: redirect('/competitions/super-lig')
  get '/ligue/liga-portugal',           to: redirect('/competitions/liga-portugal')
  get '/ligue/saudi-pro-league',        to: redirect('/competitions/saudi-pro-league')
  get '/ligue/eredivisie',              to: redirect('/competitions/eredivisie')
  get '/ligue/coupe-du-roi',            to: redirect('/competitions/coupe-du-roi')
  get '/ligue/segunda-division',        to: redirect('/competitions')
  get '/ligue/:slug',                   to: redirect('/competitions')
  get '/search',                        to: redirect('/')

  # Erreurs (en tout dernier)
  match "/404", to: "errors#not_found", via: :all
  match "*path", to: "errors#not_found", via: :all
end
