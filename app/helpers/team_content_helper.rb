module TeamContentHelper
  def generate_team_intro(team_name, stats, standing)
    return nil unless stats.present?

    played        = stats.dig("fixtures", "played", "total").to_i
    wins          = stats.dig("fixtures", "wins", "total").to_i
    draws         = stats.dig("fixtures", "draws", "total").to_i
    losses        = stats.dig("fixtures", "losses", "total").to_i
    goals_for     = stats.dig("goals", "for", "total", "total").to_i
    goals_against = stats.dig("goals", "against", "total", "total").to_i
    league_name   = stats.dig("league", "name") || "championnat"
    rank          = standing&.dig("rank")
    points        = standing&.dig("points")
    form          = stats.dig("form").to_s.last(5)

    return nil if played == 0

    avg_scored   = (goals_for.to_f / played).round(1)
    avg_conceded = (goals_against.to_f / played).round(1)
    win_rate     = (wins * 100.0 / played).round
    goal_diff    = goals_for - goals_against
    diff_label   = goal_diff >= 0 ? "+#{goal_diff}" : goal_diff.to_s
    form_wins    = form.count("W")
    form_label   = form.gsub("W", "V").gsub("D", "N").gsub("L", "D").chars.join(" ")

    # Sélection stable par nom d'équipe
    require 'zlib'
    variant = Zlib.crc32(team_name.to_s) % 10

    case variant
    when 0
      # Stats classiques : classement + bilan
      parts = []
      if rank && points
        parts << "#{team_name} est actuellement #{rank}e de #{league_name} avec #{points} point#{'s' if points > 1} au compteur."
      end
      parts << "En #{played} matchs cette saison, le club affiche #{wins} victoire#{'s' if wins > 1}, #{draws} match#{'s' if draws > 1} nul#{'s' if draws > 1} et #{losses} défaite#{'s' if losses > 1}."
      parts << "L'équipe a inscrit #{goals_for} but#{'s' if goals_for > 1} et en a encaissé #{goals_against}, pour une différence de buts de #{diff_label}."
      parts.join(" ")

    when 1
      # Focus attaque/défense
      parts = ["#{team_name} dispute la saison 2025-2026 en #{league_name}."]
      parts << "Offensivement, le club a marqué #{goals_for} but#{'s' if goals_for > 1} en #{played} matchs, soit #{avg_scored} par rencontre en moyenne."
      parts << "Défensivement, #{team_name} a concédé #{goals_against} but#{'s' if goals_against > 1} (#{avg_conceded}/match). #{win_rate >= 50 ? "Une solidité défensive qui contribue à son bon bilan cette saison." : "Un secteur à renforcer pour la suite de la saison."}"
      parts.join(" ")

    when 2
      # Focus forme récente
      parts = []
      if rank
        parts << "#{team_name} pointe à la #{rank}e place de #{league_name} après #{played} journées."
      else
        parts << "#{team_name} a disputé #{played} matchs en #{league_name} cette saison."
      end
      unless form.empty?
        parts << "Sur les 5 derniers matchs, le club affiche la séquence suivante : #{form_label}."
        parts << form_wins >= 4 ? "Une forme étincelante qui en fait l'une des équipes les plus en vue en ce moment." : form_wins <= 1 ? "Une passe difficile qui incite le club à se remobiliser rapidement." : "Un bilan en demi-teinte qui laisse de la marge de progression."
      end
      parts.join(" ")

    when 3
      # Focus taux de victoire
      parts = ["#{team_name} évolue en #{league_name} cette saison avec un bilan de #{wins} victoire#{'s' if wins > 1}, #{draws} nul#{'s' if draws > 1} et #{losses} défaite#{'s' if losses > 1} en #{played} matchs."]
      if win_rate >= 60
        parts << "Avec #{win_rate}% de victoires, #{team_name} s'impose comme l'une des formations les plus régulières du championnat."
      elsif win_rate >= 40
        parts << "Le club affiche un taux de victoire de #{win_rate}%, signe d'une équipe compétitive mais encore irrégulière."
      else
        parts << "Le taux de victoire de #{win_rate}% reflète les difficultés rencontrées cette saison par #{team_name}."
      end
      parts << "#{goals_for} buts marqués pour #{goals_against} encaissés, différence : #{diff_label}."
      parts.join(" ")

    when 4
      # Narration saison
      parts = []
      if rank && points
        parts << "Avec #{points} point#{'s' if points > 1} et une #{rank}e place en #{league_name}, #{team_name} livre une saison #{rank <= 5 ? "très solide" : rank <= 10 ? "correcte" : "compliquée"} en 2025-2026."
      end
      parts << "Le bilan de #{wins} victoire#{'s' if wins > 1} et #{losses} défaite#{'s' if losses > 1} en #{played} rencontres témoigne #{wins >= losses ? "d'une équipe compétitive à ce niveau" : "de la difficulté à s'imposer régulièrement"}."
      parts << "#{avg_scored} but#{'s' if avg_scored != 1} inscrit#{'s' if avg_scored != 1} par match en moyenne, #{avg_conceded} encaissé#{'s' if avg_conceded != 1}."
      parts.join(" ")

    when 5
      # Focus points/classement
      parts = []
      if points && rank
        pts_per_game = (points.to_f / played).round(2)
        parts << "#{team_name} totalise #{points} point#{'s' if points > 1} en #{played} matchs de #{league_name}, soit #{pts_per_game} point#{'s' if pts_per_game != 1} par rencontre."
        parts << "Le club occupe la #{rank}e place du classement #{rank <= 3 ? "— dans le haut de tableau" : rank <= 8 ? "— dans le ventre mou" : "— dans la zone délicate"}."
      else
        parts << "#{team_name} a disputé #{played} matchs en #{league_name} pour #{wins} victoire#{'s' if wins > 1}, #{draws} nul#{'s' if draws > 1} et #{losses} défaite#{'s' if losses > 1}."
      end
      parts << "Le ratio offensif de #{avg_scored} but#{'s' if avg_scored != 1} par match #{avg_scored >= 1.5 ? "en fait une équipe redoutable devant le but" : "laisse entrevoir des progrès possibles en attaque"}."
      parts.join(" ")

    when 6
      # Angle buts/efficacité
      parts = ["#{team_name} et ses #{goals_for} buts inscrits en #{played} matchs de #{league_name} cette saison."]
      if goals_for > goals_against
        parts << "L'équipe marque plus qu'elle n'encaisse (#{goals_for} pour, #{goals_against} contre), signe d'un collectif bien équilibré."
      elsif goals_for == goals_against
        parts << "Avec autant de buts marqués (#{goals_for}) qu'encaissés (#{goals_against}), #{team_name} cherche encore son équilibre."
      else
        parts << "La défense est mise à rude épreuve avec #{goals_against} buts encaissés contre #{goals_for} marqués — un déséquilibre à corriger."
      end
      parts << rank ? "Résultat : une #{rank}e place en #{league_name} après #{played} journées." : "Le bilan global : #{wins}V #{draws}N #{losses}D en #{played} matchs."
      parts.join(" ")

    when 7
      # Comparaison domicile/extérieur si dispo
      home_wins = stats.dig("fixtures", "wins", "home").to_i
      away_wins = stats.dig("fixtures", "wins", "away").to_i
      parts = ["#{team_name} évolue en #{league_name} pour la saison 2025-2026 avec #{wins} victoire#{'s' if wins > 1} au total."]
      if home_wins > 0 || away_wins > 0
        parts << "Le club se montre #{home_wins >= away_wins ? "plus efficace à domicile" : "plus performant à l'extérieur"} avec #{home_wins} victoire#{'s' if home_wins > 1} à la maison et #{away_wins} en déplacement."
      end
      parts << "#{goals_for} buts inscrits et #{goals_against} concédés sur l'ensemble de la saison."
      parts.join(" ")

    when 8
      # Angle momentum / tendance
      form_recent_wins = form.count("W")
      parts = []
      if rank
        parts << "#{rank}e de #{league_name}, #{team_name} totalise #{played} matchs joués cette saison 2025-2026."
      else
        parts << "#{team_name} a disputé #{played} matchs en #{league_name} cette saison."
      end
      momentum = form_recent_wins >= 3 ? "en pleine confiance" : form_recent_wins <= 1 ? "en quête de régularité" : "dans une forme correcte"
      parts << "Le groupe est actuellement #{momentum} avec #{form_label} sur ses 5 dernières sorties." unless form.empty?
      parts << "Au total : #{goals_for} buts pour, #{goals_against} contre — différence de #{diff_label}."
      parts.join(" ")

    when 9
      # Synthèse globale saison
      qualifier = if win_rate >= 60 then "excellente"
                  elsif win_rate >= 45 then "solide"
                  elsif win_rate >= 30 then "irrégulière"
                  else "difficile" end
      parts = ["#{team_name} signe une saison #{qualifier} en #{league_name} avec #{wins} victoire#{'s' if wins > 1} pour #{losses} défaite#{'s' if losses > 1} en #{played} matchs."]
      parts << "L'attaque a trouvé le chemin des filets à #{goals_for} reprises (#{avg_scored}/match), tandis que la défense a capitulé #{goals_against} fois (#{avg_conceded}/match)."
      parts << points ? "Bilan : #{points} point#{'s' if points > 1}#{rank ? ", #{rank}e au classement de #{league_name}" : " au compteur"}." : "Différence de buts : #{diff_label}."
      parts.join(" ")
    end
  end
end
