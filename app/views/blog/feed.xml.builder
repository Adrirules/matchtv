xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'

xml.rss version: '2.0',
         'xmlns:atom'  => 'http://www.w3.org/2005/Atom',
         'xmlns:media' => 'http://search.yahoo.com/mrss/',
         'xmlns:dc'    => 'http://purl.org/dc/elements/1.1/' do

  xml.channel do
    xml.title       "Coup d'Envoi TV - Blog football"
    xml.description "Guides pratiques, comparatifs d'abonnements et analyses football rédigés par Adrien."
    xml.link        "#{@site_url}/blog"
    xml.language    'fr'
    xml.copyright   "© #{Date.today.year} Coup d'Envoi TV"
    xml.managingEditor 'coupdenvoi@gmail.com (Adrien)'
    xml.ttl         '60'
    xml.tag!('atom:link', href: "#{@site_url}/blog.rss", rel: 'self', type: 'application/rss+xml')

    @articles.each do |article|
      xml.item do
        xml.title   article[:title]
        xml.link    "#{@site_url}/blog/#{article[:slug]}"
        xml.guid    "#{@site_url}/blog/#{article[:slug]}", isPermaLink: 'true'
        xml.description article[:excerpt].presence || article[:meta_description].to_s

        # Auteur
        xml.tag!('dc:creator', article[:author] || 'Adrien')

        # Date de publication avec heure (ex: "14h37" → 14:37 heure Paris)
        pub_time = begin
          if article[:published_time].present?
            h, m = article[:published_time].to_s.split('h').map(&:to_i)
            Time.zone.local(
              article[:published_at].year,
              article[:published_at].month,
              article[:published_at].day,
              h, m
            )
          else
            article[:published_at].to_time
          end
        rescue
          article[:published_at].to_time
        end
        xml.pubDate pub_time.rfc822

        xml.category 'Football'

        # Image si disponible (signal Google News)
        if article[:image].present?
          xml.tag!('media:thumbnail', url: article[:image], medium: 'image')
        end
      end
    end
  end
end
