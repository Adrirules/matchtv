module PlayerContentHelper
  POSITION_FR = {
    "Goalkeeper" => "gardien de but",
    "Defender"   => "défenseur",
    "Midfielder" => "milieu de terrain",
    "Attacker"   => "attaquant"
  }.freeze

  # Bloc 1 — INTRO (5 variantes)
  # Angle différent : poste, age, nationalité, équipe, carrière
  def player_intro_block(player, full_name, info, league)
    pos  = POSITION_FR[player.position] || "joueur"
    team = player.team_name
    age  = player.age || info&.dig('age')
    nat  = info&.dig('nationality').presence
    ligue = league || "sa compétition"

    case player.id % 5
    when 0
      "<strong>#{full_name}</strong> est #{pos} à <strong>#{team}</strong> pour la saison 2025-2026. " \
      "Retrouvez sur cette page ses statistiques complètes en #{ligue} et le programme TV des prochains matchs de son équipe."
    when 1
      age_str = age ? "Âgé de <strong>#{age} ans</strong>, " : ""
      nat_str = nat ? " (#{nationality_fr(nat)})" : ""
      "#{age_str}<strong>#{full_name}</strong>#{nat_str} est #{pos} professionnel sous les couleurs de <strong>#{team}</strong> cette saison. " \
      "Buts, passes décisives, note moyenne et prochains matchs TV : tout est ici."
    when 2
      nat_str = nat ? "De nationalité <strong>#{nationality_fr(nat)}</strong>, " : ""
      "#{nat_str}<strong>#{full_name}</strong> occupe le poste de #{pos} à <strong>#{team}</strong> pour la saison 2025-2026. " \
      "Ses performances en #{ligue} et le calendrier TV de son équipe sont disponibles ci-dessous."
    when 3
      "Dans l'effectif de <strong>#{team}</strong> cette saison, <strong>#{full_name}</strong> est l'un des #{pos}s " \
      "qui contribuent aux résultats du club en #{ligue}. Statistiques et programme TV à suivre ci-dessous."
    else
      "Profil complet de <strong>#{full_name}</strong>, #{pos} à <strong>#{team}</strong> en #{ligue} pour la saison 2025-2026. " \
      "Statistiques de la saison et programme TV des prochains matchs disponibles sur cette page."
    end
  end

  # Bloc 2 — STATS OFFENSIVES (4 variantes)
  # Focus différent : buts, contribution, tirs, bilan chiffré
  def player_offensive_block(player, full_name, stats, goals, assists, games, rating, minutes)
    return nil if games == 0
    shots = stats&.dig('shots', 'total').to_i
    passes_key = stats&.dig('passes', 'key').to_i

    case player.id % 4
    when 0
      base = "En <strong>#{games} match#{games > 1 ? 'es' : ''}</strong> cette saison, <strong>#{full_name}</strong> " \
             "a inscrit <strong>#{goals} but#{goals != 1 ? 's' : ''}</strong>"
      base += " et délivré <strong>#{assists} passe#{assists != 1 ? 's' : ''} décisive#{assists != 1 ? 's' : ''}</strong>" if assists > 0
      base += "."
      base += " Sa note moyenne de <strong>#{rating}/10</strong> confirme sa régularité." if rating && rating > 0
      base
    when 1
      base = "<strong>#{full_name}</strong> se montre contributif avec <strong>#{goals} réalisation#{goals != 1 ? 's' : ''}</strong>"
      base += " et <strong>#{assists} offrande#{assists != 1 ? 's' : ''} décisive#{assists != 1 ? 's' : ''}</strong>" if assists > 0
      base += " en #{games} apparition#{games > 1 ? 's' : ''} cette saison."
      base += " Ses <strong>#{minutes} minutes</strong> de temps de jeu témoignent de la confiance de l'entraîneur." if minutes > 60
      base
    when 2
      if shots > 0
        "Actif dans le dernier geste, <strong>#{full_name}</strong> a tenté <strong>#{shots} tir#{shots > 1 ? 's' : ''}</strong> " \
        "cette saison, dont <strong>#{goals}</strong> ont trouvé le chemin des filets. " \
        "Avec #{games} match#{games > 1 ? 'es' : ''} au compteur#{rating && rating > 0 ? " et une note de #{rating}/10" : ''}, " \
        "il s'affirme comme un élément fiable de l'effectif."
      else
        "<strong>#{full_name}</strong> affiche un bilan de <strong>#{goals} but#{goals != 1 ? 's' : ''}</strong>" \
        "#{assists > 0 ? " et <strong>#{assists} passe#{assists != 1 ? 's' : ''} décisive#{assists != 1 ? 's' : ''}</strong>" : ''} " \
        "en #{games} matchs cette saison. #{minutes > 0 ? "Ses #{minutes} minutes de jeu en font un élément utilisé régulièrement." : ''}"
      end
    else
      parts = ["<strong>#{goals} but#{goals != 1 ? 's' : ''}</strong>"]
      parts << "<strong>#{assists} passe#{assists != 1 ? 's' : ''} décisive#{assists != 1 ? 's' : ''}</strong>" if assists > 0
      parts << "<strong>#{games} match#{games > 1 ? 'es' : ''}</strong>"
      parts << "<strong>#{minutes}'</strong> de temps de jeu" if minutes > 0
      bilan = "Bilan 2025-2026 de <strong>#{full_name}</strong> : #{parts.join(', ')}."
      bilan += " Note moyenne : <strong>#{rating}/10</strong>." if rating && rating > 0
      bilan += " Ses passes clés traduisent une réelle vision du jeu." if passes_key > 2
      bilan
    end
  end

  # Bloc 3 — STATS DÉFENSIVES (4 variantes)
  # Focus différent : duels, interceptions, discipline, bilan
  def player_defensive_block(player, full_name, stats, games)
    return nil if games == 0 || stats.nil?
    tackles       = stats.dig('tackles', 'total').to_i
    interceptions = stats.dig('tackles', 'interceptions').to_i
    duels_total   = stats.dig('duels', 'total').to_i
    duels_won     = stats.dig('duels', 'won').to_i
    yellow        = stats.dig('cards', 'yellow').to_i
    return nil if tackles == 0 && interceptions == 0 && duels_total == 0

    case player.id % 4
    when 0
      if duels_total > 0
        pct = ((duels_won.to_f / duels_total) * 100).round
        "<strong>#{full_name}</strong> remporte <strong>#{duels_won} duels sur #{duels_total}</strong> (#{pct}%), " \
        "signe d'un engagement physique constant dans les duels."
      else
        "<strong>#{full_name}</strong> totalise <strong>#{tackles} tacle#{tackles != 1 ? 's' : ''}</strong> " \
        "et <strong>#{interceptions} interception#{interceptions != 1 ? 's' : ''}</strong> cette saison."
      end
    when 1
      base = "Appliqué dans son couloir, <strong>#{full_name}</strong> comptabilise <strong>#{interceptions} interception#{interceptions != 1 ? 's' : ''}</strong>"
      base += " et <strong>#{tackles} tacle#{tackles != 1 ? 's' : ''}</strong>" if tackles > 0
      base += " en #{games} rencontres."
      base += " Il a livré <strong>#{duels_total} duels</strong> au total cette saison." if duels_total > 0
      base
    when 2
      if duels_total > 5
        "<strong>#{full_name}</strong> a disputé <strong>#{duels_total} duels</strong> cette saison" \
        "#{duels_won > 0 ? ", en remportant <strong>#{duels_won}</strong>" : ""}. " \
        "#{interceptions > 0 ? "Ses <strong>#{interceptions} interceptions</strong> complètent un profil défensif solide." : ""}"
      else
        parts = []
        parts << "#{tackles} tacle#{tackles != 1 ? 's' : ''}" if tackles > 0
        parts << "#{interceptions} interception#{interceptions != 1 ? 's' : ''}" if interceptions > 0
        "Sur le plan défensif, <strong>#{full_name}</strong> totalise #{parts.join(' et ')} en #{games} matchs cette saison."
      end
    else
      parts = []
      parts << "<strong>#{tackles} tacle#{tackles != 1 ? 's' : ''}</strong>" if tackles > 0
      parts << "<strong>#{interceptions} interception#{interceptions != 1 ? 's' : ''}</strong>" if interceptions > 0
      parts << "<strong>#{duels_won}/#{duels_total} duels gagnés</strong>" if duels_total > 0
      return nil if parts.empty?
      disc = yellow > 0 ? " #{yellow} carton#{yellow != 1 ? 's' : ''} jaune#{yellow != 1 ? 's' : ''} au compteur." : ""
      "Statistiques défensives de <strong>#{full_name}</strong> cette saison : #{parts.join(', ')}.#{disc}"
    end
  end

  # Bloc 4 — PROFIL PHYSIQUE (4 variantes)
  # Focus différent : taille+poids, nationalité+âge, naissance, âge+période carrière
  def player_profile_block(player, full_name, info)
    return nil unless info
    age           = player.age || info['age']
    nat           = info['nationality'].presence
    height        = info['height'].presence
    weight        = info['weight'].presence
    birth_city    = info.dig('birth', 'place').presence
    birth_country = info.dig('birth', 'country').presence
    pos           = POSITION_FR[player.position] || "joueur"

    case player.id % 4
    when 0
      parts = []
      parts << "âgé de <strong>#{age} ans</strong>" if age
      parts << "de nationalité <strong>#{nationality_fr(nat)}</strong>" if nat
      parts << "mesurant <strong>#{height}</strong> pour <strong>#{weight}</strong>" if height && weight
      return nil if parts.empty?
      "<strong>#{full_name}</strong>, #{parts.join(', ')}."
    when 1
      if height && weight
        "<strong>#{full_name}</strong> présente un gabarit de <strong>#{height} pour #{weight}</strong>, " \
        "caractéristiques adaptées à son poste de #{pos}. " \
        "#{nat ? "Originaire de <strong>#{country_fr(nat)}</strong>, il évolue" : "Il évolue"} à #{player.team_name} cette saison."
      elsif nat && age
        "<strong>#{full_name}</strong> est <strong>#{nationality_fr(nat)}</strong> et est âgé de <strong>#{age} ans</strong>. " \
        "Il évolue au poste de #{pos} sous les couleurs de #{player.team_name}."
      else
        nil
      end
    when 2
      origin = if birth_city
        "né à <strong>#{birth_city}#{birth_country ? " (#{country_fr(birth_country)})" : ""}</strong>"
      elsif nat
        "originaire de <strong>#{country_fr(nat)}</strong>"
      end
      return nil unless origin || age
      "<strong>#{full_name}</strong>#{origin ? ", #{origin}," : ""} " \
      "#{age ? "a <strong>#{age} ans</strong> et" : ""} fait partie de l'effectif de <strong>#{player.team_name}</strong> pour cette saison."
    else
      return nil unless age
      period = if age < 21
        "en pleine éclosion, avec tout l'avenir devant lui"
      elsif age < 28
        "dans la plénitude de ses moyens"
      elsif age < 33
        "un joueur expérimenté qui apporte sa maturité"
      else
        "un vétéran dont l'expérience est précieuse"
      end
      "A <strong>#{age} ans</strong>, <strong>#{full_name}</strong> est #{period} " \
      "au sein de l'effectif de #{player.team_name}."
    end
  end

  # Bloc 5 — CONTEXTE LIGUE (5 variantes)
  # Formulation différente selon la compétition
  def player_league_block(player, full_name, league, team)
    ligue = league || "sa compétition"

    case player.id % 5
    when 0
      if league&.include?("Ligue 1")
        "La <strong>Ligue 1</strong> 2025-2026 est diffusée sur <strong>Canal+ et DAZN</strong> en France. " \
        "Retrouvez <strong>#{team}</strong> et <strong>#{full_name}</strong> chaque semaine sur votre écran."
      elsif league&.include?("Champions")
        "La <strong>Champions League</strong> réunit le gratin du football européen. " \
        "Suivre <strong>#{team}</strong> en coupe d'Europe, c'est voir <strong>#{full_name}</strong> face aux meilleurs du continent."
      elsif league&.include?("Premier")
        "La <strong>Premier League</strong> est le championnat le plus suivi au monde, diffusé sur <strong>Canal+</strong>. " \
        "<strong>#{full_name}</strong> et <strong>#{team}</strong> y affrontent chaque semaine l'élite du football anglais."
      else
        "<strong>#{ligue}</strong> est une compétition qui passionne des millions de supporters. " \
        "<strong>#{full_name}</strong> en est l'un des acteurs avec <strong>#{team}</strong> en 2025-2026."
      end
    when 1
      if league&.include?("Ligue 2")
        "La <strong>Ligue 2</strong> est le vivier du football français. " \
        "<strong>#{team}</strong>, avec <strong>#{full_name}</strong> dans ses rangs, " \
        "dispute chaque journée dans l'un des championnats les plus relevés du deuxième échelon européen."
      elsif league&.include?("Europa")
        "L'<strong>Europa League</strong> est la deuxième compétition européenne. " \
        "<strong>#{full_name}</strong> avec <strong>#{team}</strong> participe à cette aventure continentale " \
        "diffusée sur <strong>Canal+</strong> et <strong>RMC Sport</strong>."
      elsif league&.include?("Bundesliga")
        "La <strong>Bundesliga</strong> est réputée pour son intensité et son spectacle. " \
        "<strong>#{full_name}</strong> évolue dans ce championnat aux côtés des meilleurs joueurs européens " \
        "sous les couleurs de <strong>#{team}</strong>."
      else
        "Dans le championnat <strong>#{ligue}</strong>, <strong>#{full_name}</strong> est l'un des joueurs " \
        "qui contribuent aux résultats de <strong>#{team}</strong> au fil des journées."
      end
    when 2
      if league&.match?(/La Liga|Liga Portugal/)
        "La <strong>#{ligue}</strong> accueille certains des meilleurs joueurs du monde. " \
        "<strong>#{full_name}</strong>, sous les couleurs de <strong>#{team}</strong>, " \
        "s'y mesure chaque semaine aux géants du football ibérique."
      elsif league&.include?("Serie A")
        "La <strong>Serie A</strong> est l'une des ligues les plus tactiques d'Europe, diffusée sur <strong>beIN Sports</strong>. " \
        "<strong>#{full_name}</strong> évolue au sein de <strong>#{team}</strong> dans ce championnat exigeant."
      else
        "Chaque journée de <strong>#{ligue}</strong> est l'occasion de voir <strong>#{full_name}</strong> " \
        "à l'oeuvre avec <strong>#{team}</strong>. Un niveau professionnel exigeant qui forge les caractères."
      end
    when 3
      "Saison après saison, <strong>#{ligue}</strong> offre son lot de surprises et de grands matchs. " \
      "<strong>#{full_name}</strong> en est l'un des acteurs avec <strong>#{team}</strong>, " \
      "contribuant aux ambitions de son club en 2025-2026."
    else
      "Acteur de <strong>#{ligue}</strong>, <strong>#{full_name}</strong> défend les couleurs de <strong>#{team}</strong> " \
      "avec l'objectif de marquer la saison 2025-2026 de son empreinte."
    end
  end

  # Bloc spécial — JOUEUR SANS STATS SAISON (5 variantes)
  # Évite le duplicate content sur les centaines de joueurs sans données 2025-2026
  def player_no_stats_fallback(player, full_name, info, league, upcoming_matches)
    pos    = POSITION_FR[player.position] || "joueur"
    team   = player.team_name
    age    = player.age || info&.dig('age')
    nat    = info&.dig('nationality').presence
    ligue  = league || "sa compétition"
    next_m = upcoming_matches.first

    case player.id % 5
    when 0
      age_str = age ? "Âgé de <strong>#{age} ans</strong>, " : ""
      "#{age_str}<strong>#{full_name}</strong> fait partie de l'effectif de <strong>#{team}</strong> " \
      "pour la saison 2025-2026 en #{ligue}. " \
      "Ses statistiques individuelles ne sont pas encore comptabilisées cette saison. " \
      "Retrouvez le programme TV de son équipe ci-dessous pour suivre ses prochaines apparitions."
    when 1
      nat_str = nat ? "De nationalité <strong>#{nationality_fr(nat)}</strong>, " : ""
      "#{nat_str}<strong>#{full_name}</strong> occupe le poste de #{pos} à <strong>#{team}</strong>. " \
      "Il n'a pas encore de statistiques enregistrées en #{ligue} cette saison 2025-2026. " \
      "#{next_m ? "Le prochain match de <strong>#{team}</strong> est prévu le #{next_m.start_time.strftime('%d/%m')} contre #{next_m.home_team == team ? next_m.away_team : next_m.home_team} sur <strong>#{next_m.tv_channels}</strong>." : "Consultez le calendrier de #{team} ci-dessous pour ne pas manquer ses prochaines rencontres."}"
    when 2
      "Dans le groupe de <strong>#{team}</strong> cette saison, <strong>#{full_name}</strong> " \
      "est #{pos}#{age ? " de #{age} ans" : ""}#{nat ? " de nationalité #{nationality_fr(nat)}" : ""}. " \
      "Aucune donnée statistique 2025-2026 n'est disponible pour ce joueur pour le moment. " \
      "Son équipe dispute la #{ligue} - retrouvez le programme TV complet ci-dessous."
    when 3
      "#{full_name.split.last} figure dans l'effectif de <strong>#{team}</strong> pour " \
      "la saison 2025-2026 au poste de #{pos}. " \
      "Les statistiques de <strong>#{full_name}</strong> en #{ligue} seront disponibles au fil de la saison. " \
      "En attendant, suivez les prochains matchs de <strong>#{team}</strong> à la télé ci-dessous."
    else
      profile = [nat ? "Nationalité : <strong>#{nationality_fr(nat)}</strong>" : nil, age ? "#{age} ans" : nil, "Poste : #{pos}"].compact.join(' · ')
      "<strong>#{full_name}</strong> - #{profile}. " \
      "Aucun match comptabilisé cette saison en #{ligue}. " \
      "Le programme TV de <strong>#{team}</strong> est disponible ci-dessous pour suivre ce joueur en direct."
    end
  end

  # Bloc 6 — APPEL TV / PROCHAIN MATCH (4 variantes)
  def player_cta_block(player, full_name, team_name, upcoming_matches)
    return nil if upcoming_matches.empty?
    next_match = upcoming_matches.first
    tv = next_match.tv_channels.presence || "la chaîne dédiée"

    case player.id % 4
    when 0
      "Pour suivre <strong>#{full_name}</strong> en direct, retrouvez les prochains matchs de <strong>#{team_name}</strong> " \
      "ci-dessous avec les chaînes TV et horaires mis à jour en temps réel."
    when 1
      "Ne manquez pas les prochaines sorties de <strong>#{full_name}</strong> avec <strong>#{team_name}</strong>. " \
      "Le programme TV complet est disponible ci-dessous - heure de coup d'envoi et chaîne de diffusion inclus."
    when 2
      "Vous souhaitez regarder <strong>#{full_name}</strong> à la télévision ? " \
      "Consultez le calendrier de <strong>#{team_name}</strong> ci-dessous pour connaitre la chaîne et l'heure de chaque rencontre."
    else
      "Prochain rendez-vous TV : <strong>#{next_match.home_team} vs #{next_match.away_team}</strong> sur <strong>#{tv}</strong>. " \
      "Tout le programme de <strong>#{team_name}</strong> est disponible ci-dessous."
    end
  end
end
