# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://www.coupdenvoi.tv"

SitemapGenerator::Sitemap.create do
  # 1. On ajoute la page d'accueil (priorité haute)
  add '/', changefreq: 'hourly', priority: 1.0

  # 2. On ajoute les pages de compétitions (si tu as une route)
  # add competitions_path, changefreq: 'daily', priority: 0.8

  # 3. La MAGIE : On ajoute CHAQUE match présent en base de données
  # On ne prend que les matchs à venir ou récents
  Match.find_each do |match|
    add match_path(match),
        lastmod: match.updated_at,
        changefreq: 'daily',
        priority: 0.9
  end
end
