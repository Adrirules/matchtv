Rails.application.routes.draw do
  root to: "days#show"
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
  get "equipes", to: "teams#index", as: :teams
  get "equipes/:team_slug", to: "teams#show", as: :team

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

  # 6. Pages Statiques
  get "contact", to: "pages#contact", as: :contact
  get "a-propos", to: "pages#about", as: :a_propos
  get "mentions-legales", to: "pages#legal", as: :mentions_legales
  get "politique-de-confidentialite", to: "pages#privacy", as: :politique_confidentialite
  get "archives", to: "pages#archives", as: :archives

  # 7. MATCHS (EN DERNIER)
  # On le met en dernier pour qu'il ne "vole" pas les URLs des autres pages
  resources :matches, only: [:show], param: :slug do
    member do
      get :live_score
    end
  end

  # Erreurs (en tout dernier)
  match "/404", to: "errors#not_found", via: :all
  match "*path", to: "errors#not_found", via: :all
end
