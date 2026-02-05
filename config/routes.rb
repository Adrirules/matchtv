Rails.application.routes.draw do

  root to: "days#show"

  # Jours
  get "days/:date", to: "days#show", as: :day

  resources :matches, only: [:show], param: :slug

  # Pages Statiques
  get "contact", to: "pages#contact", as: :contact
  get "a-propos", to: "pages#about", as: :a_propos
  get "mentions-legales", to: "pages#legal", as: :mentions_legales
  get "archives", to: "pages#archives", as: :archives
# Équipes
  get "equipes", to: "teams#index", as: :teams
  get "equipe/:team_slug", to: "teams#show", as: :team

  # Compétitions
  get "ligues", to: "competitions#index", as: :competitions
  get "ligue/:slug", to: "competitions#show", as: :competition

  # Classements
  get "classement", to: "standings#index"
  get "classements", to: "standings#index", as: :standings
  get "classement/:competition_id", to: "standings#show", as: :standing

  # Sitemap
  get "sitemap.xml", to: "sitemaps#index", defaults: { format: "xml" }
end
