xml.instruct!
xml.urlset "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do
  # Accueil
  xml.url { xml.loc root_url; xml.priority 1.0; xml.changefreq "hourly" }

  # MATCHS
  @matches.each do |match|
    xml.url do
      xml.loc match_url(match.slug)
      xml.lastmod match.updated_at.to_date.to_s
      xml.priority 0.8
    end
  end

  # ÉQUIPES
  @teams.each do |team|
    xml.url do
      xml.loc team_url(team.parameterize)
      xml.priority 0.7
    end
  end

  # LIGUES / COMPÉTITIONS
  @competitions.each do |comp|
    xml.url do
      xml.loc competition_url(comp.parameterize)
      xml.priority 0.6
    end
  end

  # CLASSEMENTS (On ajoute un lien par compétition)
  @competitions.each do |comp|
    xml.url do
      xml.loc standing_url(comp.parameterize)
      xml.priority 0.5
    end
  end
end
