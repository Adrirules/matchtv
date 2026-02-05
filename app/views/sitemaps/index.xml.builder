xml.instruct! :xml, version: "1.0"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do

  # 1. Pages Principales
  xml.url { xml.loc root_url; xml.priority "1.0" }
  xml.url { xml.loc teams_url; xml.priority "0.8" }
  xml.url { xml.loc competitions_url; xml.priority "0.8" }
  xml.url { xml.loc standings_url; xml.priority "0.8" }

  # 2. Pages des 7 prochains jours
  @days.each do |day|
    xml.url do
      xml.loc day_url(day)
      xml.priority "0.9"
      xml.changefreq "daily"
    end
  end

  # 3. Compétitions (Ligue 1, etc.)
  @competitions.each do |comp|
    next if comp.blank?
    xml.url do
      xml.loc competition_url(comp.parameterize)
      xml.priority "0.8"
    end
  end

  # 4. Équipes
  @teams.each do |team|
    next if team.blank?
    xml.url do
      xml.loc team_url(team.parameterize)
      xml.priority "0.7"
      xml.changefreq "weekly"
    end
  end

  # 5. Matchups (Les 311 matchs !)
  @matchups.each do |mu|
    next if mu.slug.blank?
    xml.url do
      xml.loc match_url(mu.slug)
      xml.priority "0.6"
    end
  end
end
