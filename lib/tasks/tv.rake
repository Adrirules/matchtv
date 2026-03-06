require 'nokogiri'
require 'httparty'

namespace :tv do
  desc "Sync V42 - Mise à jour des chaînes TV (page semaine unique)"
  task sync: :environment do
    # La page principale contient déjà toute la semaine (J+6)
    # Les URLs /demain et ?j=X ne fonctionnent pas (structure différente ou paramètre ignoré)
    url = "https://www.maxifoot.fr/programme-tv-foot.htm"

    db_matches = Match.where(start_time: Time.current.beginning_of_day..7.days.from_now.end_of_day)
    puts "📋 Analyse de #{db_matches.count} matchs sur 7 jours..."

    updated_count = 0

    response = HTTParty.get(url, headers: { "User-Agent" => "Mozilla/5.0" })
    unless response.code == 200
      puts "❌ Erreur HTTP #{response.code} sur #{url}"
      return
    end

    doc = Nokogiri::HTML(response.body.force_encoding('ISO-8859-1').encode('UTF-8', invalid: :replace))
    lignes = doc.css('li[class^="c"]')

    if lignes.empty?
      puts "⚠️  ALERTE : 0 ligne trouvée — structure HTML Maxifoot modifiée !"
      return
    end

    puts "🔍 #{lignes.count} matchs trouvés sur Maxifoot"

    db_matches.each do |m|
      home_clean = m.home_team.downcase.gsub(/1\.\s|fc\s|rb\s|vfl\s|as\s|og[sc]\s|sc\s/, "").strip
      away_clean = m.away_team.downcase.gsub(/1\.\s|fc\s|rb\s|vfl\s|as\s|og[sc]\s|sc\s/, "").strip
      home_root = home_clean[0..6]
      away_root = away_clean[0..6]

      lignes.each do |li|
        line_text = li.text.downcase
        next unless line_text.include?(home_root) && line_text.include?(away_root)

        img_node = li.css('td.h1 img').first
        next unless img_node

        img_filename = img_node['src'].to_s.downcase.split('/').last

        final_ch = case
        when img_filename.include?('ligue1') then "Ligue 1+"
        when img_filename.include?('bein')
          num = img_filename.scan(/\d+/).first
          num ? "beIN Sports #{num}" : "beIN Sports"
        when img_filename.include?('canal')
          if img_filename.include?('sport360') then "Canal+ Sport 360"
          elsif img_filename.include?('sport') then "Canal+ Sport"
          elsif img_filename.include?('foot') then "Canal+ Foot"
          elsif (num = img_filename.match(/live(\d+)/)&.captures&.first) then "Canal+ Live #{num}"
          else "Canal+"
          end
        when img_filename.include?('dazn')
          num = img_filename.scan(/\d+/).first
          num ? "DAZN #{num}" : "DAZN"
        when img_filename.include?('rmc')
          num = img_filename.scan(/\d+/).first
          num ? "RMC Sport #{num}" : "RMC Sport"
        when img_filename.include?('tf1')       then "TF1"
        when img_filename.include?('m6')        then "M6"
        when img_filename.include?('w9')        then "W9"
        when img_filename.include?('france2') || img_filename.include?('france-2') || img_filename.include?('f2.') then "France 2"
        when img_filename.include?('france3') || img_filename.include?('france-3') || img_filename.include?('f3.') then "France 3"
        when img_filename.include?('france4') then "France 4"
        when img_filename.include?('france5') then "France 5"
        when img_filename.include?('amazon') || img_filename.include?('prime') then "Amazon Prime"
        when img_filename.include?('lequipe')   then "L'Equipe"
        when img_filename.include?('eurosport')
          num = img_filename.scan(/\d+/).first
          num ? "Eurosport #{num}" : "Eurosport"
        when img_filename.include?('arte')      then "Arte"
        when img_filename.include?('tmc')       then "TMC"
        end

        if final_ch && m.tv_channels != final_ch
          m.update(tv_channels: final_ch)
          puts "✅ #{m.home_team} vs #{m.away_team} → #{final_ch}"
          updated_count += 1
        end

        break
      end
    end

    puts "✨ Terminé ! #{updated_count} chaînes mises à jour."
  end
end
