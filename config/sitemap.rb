SitemapGenerator::Sitemap.default_host = "https://www.coupdenvoi.tv"
SitemapGenerator::Sitemap.compress = false

SitemapGenerator::Sitemap.create do
  add root_path, priority: 1.0, changefreq: 'hourly'
  add '/equipes', priority: 0.8
  add '/competitions', priority: 0.8
  add '/classement', priority: 0.8

  (0..7).each do |i|
    date = Time.zone.today + i.days
    add "/days/#{date}", priority: 0.9, changefreq: 'daily'
  end

  Match.select(:competition).distinct.each do |m|
    next if m.competition.blank?
    add "/competitions/#{m.competition.parameterize}", priority: 0.8, changefreq: 'daily'
  end

  # Utilisation d'une requête plus légère pour les équipes
  teams = Match.where("start_time > ?", 30.days.ago).pluck(:home_team, :away_team).flatten.uniq.compact
  teams.each do |team|
    add "/equipes/#{team.parameterize}", priority: 0.7, changefreq: 'weekly'
  end

  Match.where.not(slug: nil).where("start_time > ?", 30.days.ago).find_each do |match|
    add "/matches/#{match.slug}", priority: 0.6, lastmod: match.updated_at, changefreq: 'never'
  end
end

SitemapGenerator::Sitemap.ping_search_engines
