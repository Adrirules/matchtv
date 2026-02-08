Rails.application.routes.draw do
  root to: "days#show"
  # PRIORITÉ N°1 : Le sitemap (format XML forcé)
  get "sitemap.xml", to: "sitemaps#index", defaults: { format: "xml" }
  # 2. Les jours
  get "days/:date", to: "days#show", as: :day

  # 3. Équipes
  get "equipes", to: "teams#index", as: :teams
  get "equipes/:team_slug", to: "teams#show", as: :team

  # 4. Compétitions
  get "competitions", to: "competitions#index", as: :competitions
  get "competitions/:slug", to: "competitions#show", as: :competition

  # 5. Classements
  get "classement", to: "standings#index"
  get "classements", to: "standings#index", as: :standings
  get "classements/:competition_id", to: "standings#show", as: :standing

  # 6. Pages Statiques
  get "contact", to: "pages#contact", as: :contact
  get "a-propos", to: "pages#about", as: :a_propos
  get "mentions-legales", to: "pages#legal", as: :mentions_legales
  get "archives", to: "pages#archives", as: :archives

  # 7. MATCHS (EN DERNIER)
  # On le met en dernier pour qu'il ne "vole" pas les URLs des autres pages
  resources :matches, only: [:show], param: :slug
end
