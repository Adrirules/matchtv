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

  # CLASSEMENTS (14 ligues avec slugs officiels)
  @standing_slugs.each do |slug|
    xml.url do
      xml.loc standing_url(slug)
      xml.changefreq "daily"
      xml.priority 0.8
    end
  end

  # CHAÎNES TV
  xml.url { xml.loc channels_url; xml.changefreq "weekly"; xml.priority 0.7 }
  @channel_slugs.each do |slug|
    xml.url do
      xml.loc channel_url(slug)
      xml.changefreq "weekly"
      xml.priority 0.7
    end
  end

  # BLOG
  xml.url { xml.loc blog_url; xml.changefreq "weekly"; xml.priority 0.6 }
  @blog_articles.each do |article|
    xml.url do
      xml.loc blog_article_url(article[:slug])
      xml.lastmod article[:date].to_s
      xml.priority 0.6
    end
  end

  # JOUEURS
  @players.each do |player|
    next if player.slug.blank?
    xml.url do
      xml.loc player_url(player.slug)
      xml.lastmod player.updated_at&.to_date.to_s
      xml.priority 0.7
    end
  end
end
