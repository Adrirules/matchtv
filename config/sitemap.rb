# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://www.coupdenvoi.tv"

# Prévenir Google et Bing à chaque mise à jour du sitemap
SitemapGenerator::Sitemap.ping_google

SitemapGenerator::Sitemap.create do
  # 1. Pages Principales
  add root_path, priority: 1.0, changefreq: 'hourly'
  add '/equipes', priority: 0.8
  add '/competitions', priority: 0.8
  add '/classement', priority: 0.8

  # 2. Pages des jours
  # Programme pour les 7 prochains jours
  (0..7).each do |i|
    date = Date.today + i.days
    add "/days/#{date}", priority: 0.9, changefreq: 'daily'
  end

  # 3. Compétitions
  # On récupère les compétitions uniques en base
  Match.pluck(:competition).uniq.compact.each do |comp|
    add "/competitions/#{comp.parameterize}", priority: 0.8, changefreq: 'daily'
  end

  # 4. Équipes
  # On récupère tous les noms d'équipes (home et away)
  teams = Match.pluck(:home_team, :away_team).flatten.uniq.compact
  teams.each do |team|
    add "/equipes/#{team.parameterize}", priority: 0.7, changefreq: 'weekly'
  end

  # 5. MATCHS
  # On boucle sur les matchs ayant un slug
  Match.where.not(slug: nil).find_each do |match|
    # On construit l'URL manuellement pour éviter les erreurs de helper dans le sitemap
    add "/matches/#{match.slug}", priority: 0.6, lastmod: match.updated_at, changefreq: 'never'
  end
end
