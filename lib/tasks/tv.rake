require 'nokogiri'
require 'httparty'

namespace :tv do
  desc "Sync V40 - Mise à jour des matchs existants uniquement"
  task sync: :environment do
    urls = [
      "https://www.maxifoot.fr/programme-tv-foot.htm",
      "https://www.maxifoot.fr/programme-tv-foot-demain.htm",
      "https://www.maxifoot.fr/programme-tv-foot-apres-demain.htm"
    ]

    # On ne travaille que sur les matchs que tu as déjà en base
    db_matches = Match.where(start_time: Time.current.beginning_of_day..3.days.from_now.end_of_day)
    puts "📋 Analyse de #{db_matches.count} matchs présents en base..."

    updated_count = 0

    urls.each do |url|
      response = HTTParty.get(url, headers: { "User-Agent" => "Mozilla/5.0" })
      next unless response.code == 200

      doc = Nokogiri::HTML(response.body.force_encoding('ISO-8859-1').encode('UTF-8'))
      lignes = doc.css('li[class^="c"]')

      db_matches.each do |m|
        # Nettoyage des noms pour le matching (Augsburg, Wolfsburg, etc.)
        home_root = m.home_team.downcase.gsub(/1\.\s|fc\s|rb\s|vfl\s/, "").strip[0..4]
        away_root = m.away_team.downcase.gsub(/1\.\s|fc\s|rb\s|vfl\s/, "").strip[0..4]

        lignes.each do |li|
          line_text = li.text.downcase

          # Si on trouve une correspondance entre ton match "en dur" et Maxifoot
          if line_text.include?(home_root) && line_text.include?(away_root)
            img_node = li.css('td.h1 img').first
            next unless img_node

            img_filename = img_node['src'].to_s.downcase.split('/').last

            # Détection de la chaîne (logique haute précision)
            final_ch = case
            when img_filename.include?('ligue1') then "Ligue 1+"
            when img_filename.include?('bein')
              num = img_filename.scan(/\d+/).first
              num ? "beIN Sports #{num}" : "beIN Sports"
            when img_filename.include?('dazn')
              num = img_filename.scan(/\d+/).first
              num ? "DAZN #{num}" : "DAZN"
            when img_filename.include?('canal')
              if img_filename.include?('sport') then "Canal+ Sport"
              elsif img_filename.include?('foot') then "Canal+ Foot"
              else "Canal+"
              end
            when img_filename.include?('lequipe') then "L'Equipe"
            when img_filename.include?('eurosport') then "Eurosport"
            end

            # MISE À JOUR : On écrase l'ancien "À confirmer" par la vraie chaîne
            if final_ch && m.tv_channels != final_ch
              m.update(tv_channels: final_ch)
              puts "✅ MAJ : #{m.home_team} vs #{m.away_team} ➡️  #{final_ch}"
              updated_count += 1
            end
            break # On a trouvé le match sur cette page, on passe au match suivant de la DB
          end
        end
      end
    end
    puts "✨ Terminé ! #{updated_count} matchs synchronisés avec succès."
  end
end
