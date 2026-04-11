module SeoHelper
  def meta_title(title)
    content_for(:title) { title }
  end

  def meta_description(description)
    content_for(:meta_description) { description }
  end

  def generate_match_seo(match)
    ht = team_display_name(match.home_team)
    at = team_display_name(match.away_team)
    match_name = "#{ht} - #{at}"

    if match.finished? && match.has_score?
      score = "#{match.home_score}-#{match.away_score}"
      comp  = match.competition

      winner_phrase = if match.home_score.to_i > match.away_score.to_i
        "#{ht} s'impose #{score}"
      elsif match.away_score.to_i > match.home_score.to_i
        "#{at} s'impose #{score}"
      else
        "match nul #{score}"
      end

      result_templates = [
        {
          title: "%{h} %{score} %{a} - Résultat et résumé %{comp} | Coup d'Envoi TV",
          desc: "Résultat %{h} - %{a} : %{winner}. Retrouvez le résumé complet et les stats de ce match de %{comp}."
        },
        {
          title: "Résultat %{h} vs %{a} (%{score}) - %{comp} | Coup d'Envoi TV",
          desc: "Score final %{h} - %{a} : %{score} en %{comp}. Résumé du match, faits marquants et classement mis à jour."
        },
        {
          title: "%{h} - %{a} : score %{score} et résumé du match | Coup d'Envoi TV",
          desc: "%{winner} face à %{a} en %{comp} (%{score}). Compte-rendu complet de la rencontre sur Coup d'Envoi TV."
        },
        {
          title: "Score %{h} - %{a} : %{score} - Résumé %{comp} | Coup d'Envoi TV",
          desc: "Vous cherchez le résultat de %{h} - %{a} ? Score final : %{score} en %{comp}. Résumé et analyse de la rencontre."
        }
      ]

      template = result_templates[match.id % result_templates.size]
      meta_title(template[:title] % { h: ht, a: at, score: score, comp: comp })
      meta_description(template[:desc] % { h: ht, a: at, score: score, comp: comp, winner: winner_phrase })
    else
      time    = match.start_time.strftime("%Hh%M")
      channel = match.tv_channels.to_s
      date    = match.start_time.strftime("%-d/%m")
      comp    = match.competition.to_s

      upcoming_templates = [
        {
          title: "%{match} : Chaîne TV, Heure et Direct | Coup d'Envoi TV",
          desc:  "%{match} à %{time} sur %{channel}. Sur quelle chaîne et comment regarder ce match en streaming légal ?"
        },
        {
          title: "%{match} : sur quelle chaîne voir le match ? | Coup d'Envoi TV",
          desc:  "Diffusion de %{match} le %{date} à %{time} sur %{channel}. Heure de coup d'envoi et accès streaming confirmés."
        },
        {
          title: "%{match} - Heure, chaîne TV et streaming | Coup d'Envoi TV",
          desc:  "Coup d'envoi à %{time} sur %{channel} pour %{match}. Retrouvez toutes les infos pour suivre ce match en direct."
        },
        {
          title: "Où voir %{match} ? Chaîne et heure | Coup d'Envoi TV",
          desc:  "%{match} : rendez-vous à %{time} sur %{channel}. Guide complet pour regarder ce match en direct ou en streaming."
        },
        {
          title: "%{match} en direct : chaîne TV et coup d'envoi | Coup d'Envoi TV",
          desc:  "Ce match de %{comp} débute à %{time} sur %{channel}. Retrouvez l'heure exacte et comment y accéder en streaming."
        },
        {
          title: "%{match} : programme TV et streaming | Coup d'Envoi TV",
          desc:  "%{match} est à suivre à %{time} sur %{channel}. Abonnement et streaming légal disponibles sur l'application officielle."
        }
      ]

      template = upcoming_templates[match.id % upcoming_templates.size]
      meta_title(template[:title] % { match: match_name })
      meta_description(template[:desc] % {
        match: match_name, time: time, channel: channel, comp: comp, date: date
      })
    end
  end

  # 10 variations du bloc "Détails diffusion" - sélection stable par match.id
  def generate_match_diffusion_paragraphs(match)
    h   = team_display_name(match.home_team)
    a   = team_display_name(match.away_team)
    ch  = match.tv_channels.to_s
    hr  = match.start_time.strftime("%Hh%M")
    cp  = match.competition

    variations = [
      # 0 - Standard informatif
      [
        "Le match <strong>#{h}</strong> contre <strong>#{a}</strong> est à suivre dans le cadre de la <strong>#{cp}</strong>. La rencontre sera retransmise en direct à <strong>#{hr}</strong> sur <strong>#{ch}</strong>.",
        "Pour regarder <strong>#{h} - #{a}</strong> en streaming légal depuis votre smartphone, tablette ou ordinateur, connectez-vous à l'application officielle de <strong>#{ch}</strong> avec votre abonnement actif.",
        "Un abonnement <strong>#{ch}</strong> vous donnera également accès à d'autres matchs de <strong>#{cp}</strong> tout au long de la saison 2025-2026."
      ],
      # 1 - Chaîne en avant
      [
        "C'est <strong>#{ch}</strong> qui retransmet en exclusivité ce match de <strong>#{cp}</strong> entre <strong>#{h}</strong> et <strong>#{a}</strong>, à partir de <strong>#{hr}</strong>.",
        "Pour ne pas rater cette affiche, vérifiez votre accès à <strong>#{ch}</strong> via votre box TV, votre Smart TV ou l'application mobile dédiée. L'accès au streaming nécessite un abonnement en cours de validité.",
        "<strong>#{h}</strong> et <strong>#{a}</strong> s'affrontent dans un duel de <strong>#{cp}</strong> que les abonnés <strong>#{ch}</strong> pourront suivre en direct et en intégralité dès <strong>#{hr}</strong>."
      ],
      # 2 - Format questions/réponses
      [
        "<strong>Où regarder #{h} vs #{a} ?</strong> Ce match de <strong>#{cp}</strong> est diffusé à <strong>#{hr}</strong> sur <strong>#{ch}</strong>.",
        "<strong>Comment voir #{h} - #{a} en streaming ?</strong> Connectez-vous à l'espace abonné de <strong>#{ch}</strong> sur votre application ou votre navigateur. La qualité HD est disponible selon votre abonnement et votre connexion internet.",
        "Cette affiche de <strong>#{cp}</strong> s'annonce comme un rendez-vous incontournable, à ne manquer sous aucun prétexte sur <strong>#{ch}</strong> à <strong>#{hr}</strong>."
      ],
      # 3 - Heure en avant
      [
        "Rendez-vous à <strong>#{hr}</strong> pour suivre <strong>#{h}</strong> face à <strong>#{a}</strong> en <strong>#{cp}</strong>. La diffusion est assurée par <strong>#{ch}</strong> sur toutes ses plateformes.",
        "<strong>#{ch}</strong> proposera la rencontre en direct sur ses antennes. Pensez à activer votre abonnement pour en profiter sur tous vos écrans - téléviseur, ordinateur, smartphone ou tablette.",
        "Le coup d'envoi de ce match de <strong>#{cp}</strong> est fixé à <strong>#{hr}</strong>. <strong>#{h}</strong> et <strong>#{a}</strong> s'élancent pour une rencontre à suivre en intégralité sur <strong>#{ch}</strong>."
      ],
      # 4 - Contexte compétition
      [
        "Dans le cadre de la <strong>#{cp}</strong>, <strong>#{h}</strong> et <strong>#{a}</strong> se retrouvent pour une nouvelle rencontre. Coup d'envoi prévu à <strong>#{hr}</strong> sur <strong>#{ch}</strong>.",
        "La chaîne <strong>#{ch}</strong> retransmet l'intégralité du match en direct. Pour les abonnés, l'accès est disponible sur toutes les plateformes officielles du diffuseur - télévision, streaming mobile et replay après le match.",
        "Rendez-vous sur <strong>#{ch}</strong> à <strong>#{hr}</strong> pour vivre en direct ce match de <strong>#{cp}</strong> entre <strong>#{h}</strong> et <strong>#{a}</strong>."
      ],
      # 5 - Streaming en avant
      [
        "Le match <strong>#{h} vs #{a}</strong> de <strong>#{cp}</strong> est retransmis en direct à <strong>#{hr}</strong> sur <strong>#{ch}</strong>.",
        "Pour suivre ce match en streaming depuis votre smartphone ou ordinateur, l'application officielle de <strong>#{ch}</strong> est votre meilleure option. Un abonnement en cours est requis pour accéder au direct comme au replay.",
        "<strong>#{h}</strong> et <strong>#{a}</strong> s'élancent à <strong>#{hr}</strong> dans cette rencontre de <strong>#{cp}</strong>. Toute la rencontre est sur <strong>#{ch}</strong>."
      ],
      # 6 - Guide pratique
      [
        "Voici comment regarder <strong>#{h} vs #{a}</strong> en <strong>#{cp}</strong> : le match est diffusé à <strong>#{hr}</strong> sur <strong>#{ch}</strong>.",
        "Pour accéder à la diffusion, vous aurez besoin d'un abonnement <strong>#{ch}</strong>. L'application officielle permet de suivre ce match en streaming sur mobile, tablette et ordinateur, en plus de la diffusion sur votre téléviseur.",
        "Ne manquez pas le coup d'envoi à <strong>#{hr}</strong> : <strong>#{h}</strong> et <strong>#{a}</strong> s'affrontent dans ce match de <strong>#{cp}</strong> retransmis sur <strong>#{ch}</strong>."
      ],
      # 7 - Angle abonné / fidélité
      [
        "<strong>#{h}</strong> reçoit <strong>#{a}</strong> pour ce match de <strong>#{cp}</strong> diffusé à <strong>#{hr}</strong> sur <strong>#{ch}</strong>.",
        "En tant qu'abonné <strong>#{ch}</strong>, vous pouvez accéder au match en direct sur votre téléviseur via votre box, mais aussi en streaming sur l'application officielle. La retransmission complète inclut commentaires, statistiques et replays.",
        "<strong>#{cp}</strong> 2025-2026 : <strong>#{h}</strong> et <strong>#{a}</strong> se disputent trois points cruciaux dans ce match programmé à <strong>#{hr}</strong> sur <strong>#{ch}</strong>."
      ],
      # 8 - Informatif enrichi
      [
        "<strong>#{h}</strong> et <strong>#{a}</strong> se retrouvent pour une affiche de <strong>#{cp}</strong> à <strong>#{hr}</strong>. La rencontre est à suivre sur <strong>#{ch}</strong>.",
        "La chaîne <strong>#{ch}</strong> retransmet l'intégralité du match en direct et en haute définition. Pour les abonnés, l'accès streaming est disponible sur toutes les plateformes officielles du diffuseur, y compris le replay après le coup de sifflet final.",
        "Coup d'envoi à <strong>#{hr}</strong> pour ce <strong>#{cp}</strong>. Préparez votre soirée : <strong>#{h}</strong> - <strong>#{a}</strong>, en direct sur <strong>#{ch}</strong>."
      ],
      # 9 - Court et percutant
      [
        "<strong>#{h} - #{a}</strong> : match de <strong>#{cp}</strong> diffusé à <strong>#{hr}</strong> sur <strong>#{ch}</strong>.",
        "Pour regarder ce match en streaming légal, connectez-vous à l'espace abonné de <strong>#{ch}</strong> sur votre application mobile ou votre box TV. La diffusion démarre à <strong>#{hr}</strong> heure française.",
        "Les deux équipes s'élancent dans cette rencontre de <strong>#{cp}</strong>. Abonnez-vous à <strong>#{ch}</strong> pour profiter du match en direct, en replay et de tous les matchs de la saison."
      ],
      # 10 - Angle impatience / événement
      [
        "Ce soir à <strong>#{hr}</strong>, <strong>#{h}</strong> et <strong>#{a}</strong> montent sur la pelouse pour ce match de <strong>#{cp}</strong>. Diffusion en direct sur <strong>#{ch}</strong>.",
        "Si vous ne voulez pas rater le coup d'envoi, vérifiez dès maintenant votre accès à <strong>#{ch}</strong>. Smart TV, mobile, ordinateur - le direct est disponible sur tous vos écrans.",
        "Une affiche de <strong>#{cp}</strong> qui s'annonce intéressante : <strong>#{h}</strong> face à <strong>#{a}</strong>, à ne pas manquer sur <strong>#{ch}</strong> à <strong>#{hr}</strong>."
      ],
      # 11 - Angle accessibilité / simplicité
      [
        "Pas besoin de chercher longtemps : <strong>#{h} - #{a}</strong> est sur <strong>#{ch}</strong> à <strong>#{hr}</strong> dans le cadre de la <strong>#{cp}</strong>.",
        "L'accès au direct est simple : ouvrez l'application <strong>#{ch}</strong>, identifiez-vous avec vos identifiants d'abonné et profitez du match où que vous soyez.",
        "<strong>#{h}</strong> contre <strong>#{a}</strong> en <strong>#{cp}</strong> - un duel à vivre en intégralité sur les antennes de <strong>#{ch}</strong> à partir de <strong>#{hr}</strong>."
      ],
      # 12 - Angle récit
      [
        "<strong>#{h}</strong> reçoit <strong>#{a}</strong> ce soir dans le cadre de la <strong>#{cp}</strong>. Rendez-vous à <strong>#{hr}</strong> pour suivre l'événement en direct sur <strong>#{ch}</strong>.",
        "Les supporters des deux camps vont pouvoir vibrer : <strong>#{ch}</strong> retransmet l'intégralité de cette rencontre, des échauffements au coup de sifflet final.",
        "Pour accéder au streaming depuis votre téléphone ou tablette, l'application <strong>#{ch}</strong> est disponible sur iOS et Android. Pensez à activer votre abonnement avant le coup d'envoi de <strong>#{hr}</strong>."
      ],
      # 13 - Angle pratique / multi-écrans
      [
        "Le match <strong>#{h} vs #{a}</strong> est programmé à <strong>#{hr}</strong> sur <strong>#{ch}</strong>, dans le cadre de la compétition <strong>#{cp}</strong>.",
        "Depuis votre canapé, <strong>#{ch}</strong> retransmet la rencontre sur votre télévision. En déplacement ? L'application mobile vous permet de suivre le direct depuis votre smartphone ou tablette avec votre abonnement habituel.",
        "Coup d'envoi à <strong>#{hr}</strong> pour <strong>#{h}</strong> et <strong>#{a}</strong> en <strong>#{cp}</strong>. La qualité de diffusion est garantie en HD sur toutes les plateformes <strong>#{ch}</strong>."
      ],
      # 14 - Angle question rhétorique
      [
        "Vous vous demandez où regarder <strong>#{h} - #{a}</strong> ce soir ? La réponse est simple : <strong>#{ch}</strong>, à <strong>#{hr}</strong>, pour ce match de <strong>#{cp}</strong>.",
        "<strong>#{ch}</strong> détient les droits de diffusion de cette rencontre et la propose en direct sur l'ensemble de ses plateformes. Avec ou sans télévision, vous ne manquerez rien.",
        "Un abonnement <strong>#{ch}</strong> vous donne accès non seulement à ce <strong>#{cp}</strong>, mais aussi à l'ensemble du calendrier de la compétition jusqu'en fin de saison."
      ],
      # 15 - Angle compétition en avant
      [
        "La <strong>#{cp}</strong> s'invite dans votre soirée avec ce <strong>#{h}</strong> contre <strong>#{a}</strong> diffusé à <strong>#{hr}</strong> sur <strong>#{ch}</strong>.",
        "Fidèle partenaire de la <strong>#{cp}</strong>, <strong>#{ch}</strong> vous propose ce match en intégralité et en direct. Connectez-vous à l'application ou allumez votre téléviseur avant <strong>#{hr}</strong>.",
        "Trois points sont en jeu pour les deux équipes dans cette rencontre de <strong>#{cp}</strong>. La diffusion est assurée par <strong>#{ch}</strong>, en direct dès <strong>#{hr}</strong>."
      ],
      # 16 - Angle préparation / ritual
      [
        "Installez-vous confortablement : <strong>#{h} - #{a}</strong> commence à <strong>#{hr}</strong> sur <strong>#{ch}</strong> dans le cadre de la <strong>#{cp}</strong>.",
        "Pour regarder ce match sans interruption, assurez-vous que votre abonnement <strong>#{ch}</strong> est actif. La chaîne propose également les statistiques en temps réel et le replay après le match.",
        "<strong>#{h}</strong> et <strong>#{a}</strong> s'affrontent dans ce qui s'annonce comme une belle joute de <strong>#{cp}</strong>, à suivre sur <strong>#{ch}</strong> à <strong>#{hr}</strong> heure française."
      ],
      # 17 - Angle confirmé / factuel pur
      [
        "Confirmé : <strong>#{h} - #{a}</strong> est bien diffusé sur <strong>#{ch}</strong> à <strong>#{hr}</strong>, dans le cadre de la journée de <strong>#{cp}</strong>.",
        "Le streaming légal est accessible via l'espace abonné de <strong>#{ch}</strong> sur navigateur ou application. La qualité HD est incluse dans tous les abonnements, sous réserve d'une connexion suffisante.",
        "Un match de <strong>#{cp}</strong> qui oppose deux équipes avec leurs ambitions propres pour cette saison 2025-2026. En direct sur <strong>#{ch}</strong> à <strong>#{hr}</strong>."
      ],
      # 18 - Angle soirée / programme TV
      [
        "Au programme ce soir sur <strong>#{ch}</strong> : <strong>#{h}</strong> contre <strong>#{a}</strong> à <strong>#{hr}</strong> en <strong>#{cp}</strong>.",
        "Pour les fans qui préfèrent le streaming, l'application <strong>#{ch}</strong> est disponible sur smart TV, Apple TV, Chromecast et consoles de jeu, en plus du mobile et de l'ordinateur.",
        "Un duel de <strong>#{cp}</strong> entre <strong>#{h}</strong> et <strong>#{a}</strong> à ne pas rater : retrouvez toute l'action en direct sur <strong>#{ch}</strong> dès <strong>#{hr}</strong>."
      ],
      # 19 - Angle minimaliste / direct
      [
        "<strong>#{h}</strong> vs <strong>#{a}</strong> — <strong>#{cp}</strong> — <strong>#{hr}</strong> sur <strong>#{ch}</strong>.",
        "Pour regarder : ouvrez <strong>#{ch}</strong> sur votre box, votre télé connectée ou l'application mobile. Abonnement requis pour accéder au direct.",
        "Coup d'envoi à <strong>#{hr}</strong>. <strong>#{h}</strong> et <strong>#{a}</strong> s'affrontent en <strong>#{cp}</strong>, retransmis en intégralité sur <strong>#{ch}</strong>."
      ]
    ]

    variations[match.id % variations.size]
  end

  # 20 sets de FAQ variées selon match.id — questions et réponses différentes à chaque fois
  def generate_match_faq(match)
    h   = team_display_name(match.home_team)
    a   = team_display_name(match.away_team)
    ch  = match.tv_channels.to_s
    hr  = match.start_time.strftime("%Hh%M")
    cp  = match.competition.to_s
    date_label = date_fr(match.start_time.to_date)

    if match.finished? && match.has_score?
      score = "#{match.home_score}-#{match.away_score}"
      winner = match.home_score.to_i > match.away_score.to_i ? h : match.away_score.to_i > match.home_score.to_i ? a : nil

      finished_sets = [
        [
          { q: "Quel est le score de #{h} - #{a} ?", a: "Le match #{h} - #{a} s'est terminé sur le score de #{score} en #{cp}." },
          { q: "Qui a gagné #{h} contre #{a} ?", a: winner ? "C'est #{winner} qui s'est imposé sur le score de #{score}." : "Les deux équipes se sont séparées sur un match nul #{score}." },
          { q: "Où voir le résumé de #{h} - #{a} ?", a: "Le résumé complet de #{h} - #{a} est disponible sur cette page. Retrouvez également le replay sur l'application officielle de #{ch}." }
        ],
        [
          { q: "Résultat #{h} - #{a} : quel est le score final ?", a: "Score final : #{h} #{score} #{a} en #{cp}." },
          { q: "Comment s'est passé le match #{h} vs #{a} ?", a: winner ? "#{winner} a remporté cette rencontre de #{cp} sur le score de #{score}." : "Match nul entre #{h} et #{a} : #{score} dans cette rencontre de #{cp}." },
          { q: "Puis-je voir le replay de #{h} - #{a} ?", a: "Oui, le replay est disponible sur les plateformes officielles de #{ch}, généralement dans les heures qui suivent le coup de sifflet final." }
        ],
        [
          { q: "#{h} - #{a} : qui a remporté le match ?", a: winner ? "#{winner} s'est imposé #{score} dans ce match de #{cp}." : "#{h} et #{a} ont fait match nul #{score} en #{cp}." },
          { q: "Quel était l'enjeu de #{h} contre #{a} ?", a: "Cette rencontre comptait pour la #{cp} lors de la saison 2025-2026." },
          { q: "Où revoir #{h} - #{a} en vidéo ?", a: "Le match #{h} - #{a} est disponible en replay sur l'application et le site de #{ch}." }
        ],
        [
          { q: "Score final de #{h} vs #{a} en #{cp} ?", a: "Le match s'est conclu sur le score de #{score}. #{winner ? "#{winner} repart avec la victoire." : "Aucune équipe n'a su faire la différence."}" },
          { q: "Ce match de #{cp} comptait pour quel classement ?", a: "#{h} - #{a} était une rencontre officielle de #{cp}. Consultez le classement mis à jour sur notre page dédiée." },
          { q: "Comment avoir accès au replay ?", a: "Le replay de #{h} - #{a} est accessible sur #{ch} pour les abonnés, ainsi que sur cette page avec le résumé éditorial." }
        ],
        [
          { q: "#{h} a-t-il gagné contre #{a} ?", a: match.home_score.to_i > match.away_score.to_i ? "Oui, #{h} s'est imposé #{score} face à #{a} en #{cp}." : match.home_score.to_i < match.away_score.to_i ? "Non, #{a} a remporté la victoire #{score} face à #{h} en #{cp}." : "Non, les deux équipes ont fait match nul #{score} en #{cp}." },
          { q: "Quelle était la cote de ce match #{cp} ?", a: "#{h} et #{a} se sont affrontés dans le cadre de la #{cp} 2025-2026. Le score final #{score} est à retrouver sur cette page." },
          { q: "Replay #{h} - #{a} : comment le regarder ?", a: "Connectez-vous à l'espace abonné de #{ch} pour accéder au replay complet de #{h} - #{a} en #{cp}." }
        ],
        # 5
        [
          { q: "#{h} - #{a} : combien de buts dans ce match de #{cp} ?", a: "#{h} et #{a} ont inscrit #{match.home_score.to_i + match.away_score.to_i} but(s) au total dans cette rencontre de #{cp} terminée #{score}." },
          { q: "Où revoir les buts de #{h} vs #{a} ?", a: "Les buts de #{h} - #{a} (#{score}) sont disponibles en replay sur l'application #{ch}. Le résumé éditorial est également sur cette page." },
          { q: "#{winner ? "#{winner} reste-t-il dans le top du classement #{cp} ?" : "Ce match nul #{score} change-t-il le classement #{cp} ?"}", a: "#{winner ? "Cette victoire #{score} est un bon point pour #{winner} en #{cp}. Consultez le classement mis à jour sur la page de la compétition." : "Ce match nul #{score} entre #{h} et #{a} rapporte 1 point à chaque équipe en #{cp}. Le classement est disponible sur notre page dédiée."}" }
        ],
        # 6
        [
          { q: "Quel est le résultat de #{h} contre #{a} en #{cp} ?", a: "#{winner ? "#{winner} s'est imposé #{score} face à #{match.home_score.to_i > match.away_score.to_i ? a : h} dans ce match de #{cp}." : "#{h} et #{a} se sont quittés sur un nul #{score} en #{cp}."}" },
          { q: "Y avait-il un enjeu particulier pour #{h} - #{a} ?", a: "Cette rencontre comptait pour la #{cp} saison 2025-2026. Retrouvez les prochains matchs des deux équipes sur leurs pages respectives." },
          { q: "#{h} - #{a} #{score} : peut-on voir le résumé vidéo ?", a: "Le résumé de #{h} - #{a} (#{score}) est accessible sur #{ch} pour les abonnés, ainsi que sur cette page." }
        ],
        # 7
        [
          { q: "Combien de points #{winner ? "#{winner} a-t-il pris" : "chaque équipe a-t-elle pris"} contre #{winner ? (match.home_score.to_i > match.away_score.to_i ? a : h) : "l'autre"} ?", a: "#{winner ? "#{winner} repart avec 3 points après sa victoire #{score} en #{cp}." : "#{h} et #{a} prennent chacun 1 point après ce nul #{score} en #{cp}."}" },
          { q: "Ce match #{h} - #{a} s'est joué dans quel stade ?", a: "#{h} recevait #{a} à domicile pour ce match de #{cp}. Score final : #{score}." },
          { q: "Résultat #{cp} du #{date_label} : #{h} - #{a} ?", a: "#{winner ? "#{winner} l'a emporté #{score} sur #{match.home_score.to_i > match.away_score.to_i ? a : h}." : "Nul #{score} entre #{h} et #{a}."} Résultat enregistré lors de la journée #{cp} du #{date_label}." }
        ],
        # 8
        [
          { q: "#{h} - #{a} : ce score #{score} était-il prévisible ?", a: "#{winner ? "#{winner} s'est montré plus fort #{score} dans cette rencontre de #{cp}." : "Les deux équipes ont rendu une copie équilibrée avec un nul #{score} en #{cp}."}" },
          { q: "Comment #{winner ? winner : "les deux équipes"} #{winner ? "a-t-il" : "ont-elles"} performé dans ce #{cp} ?", a: "Le résumé complet de #{h} - #{a} (#{score}) est disponible sur cette page. Retrouvez aussi les stats détaillées sur #{ch}." },
          { q: "Ce résultat #{score} en #{cp} impacte-t-il le classement ?", a: "#{winner ? "La victoire #{score} de #{winner} lui permet de grappiller des points en #{cp}." : "Le match nul #{score} entre #{h} et #{a} répartit équitablement les points en #{cp}."} Classement mis à jour sur notre page dédiée." }
        ],
        # 9
        [
          { q: "#{a} a-t-il perdu face à #{h} ?", a: match.home_score.to_i > match.away_score.to_i ? "Oui, #{a} s'est incliné #{score} face à #{h} en #{cp}." : match.home_score.to_i < match.away_score.to_i ? "Non, c'est #{a} qui a gagné #{score} à l'extérieur en #{cp}." : "Non, le match s'est terminé sur un nul #{score} entre #{h} et #{a} en #{cp}." },
          { q: "Où trouver la fiche complète du match #{h} - #{a} ?", a: "Vous êtes déjà dessus. Score : #{score} en #{cp}. Résumé, faits de jeu et replay disponibles ci-dessus." },
          { q: "#{h} - #{a} en #{cp} : qui a inscrit les buts ?", a: "Les buteurs de #{h} - #{a} (#{score}) sont détaillés dans la timeline des événements sur cette page." }
        ],
        # 10
        [
          { q: "Résultat final #{h} vs #{a} : #{score} est-ce exact ?", a: "Oui, le score final officiel de #{h} - #{a} en #{cp} est bien #{score}." },
          { q: "Y a-t-il eu des prolongations dans #{h} - #{a} ?", a: "Le score final de #{h} - #{a} en #{cp} est #{score}. Les détails du déroulement du match sont disponibles dans la section résumé ci-dessus." },
          { q: "Comment se portent #{h} et #{a} dans le classement #{cp} après ce match ?", a: "Consultez le classement #{cp} sur notre page dédiée pour voir la situation de #{h} et #{a} après ce résultat #{score}." }
        ],
        # 11
        [
          { q: "#{h} - #{a} #{score} : match nul ou victoire ?", a: "#{winner ? "Victoire de #{winner} sur le score de #{score} en #{cp}." : "Match nul #{score} entre #{h} et #{a} en #{cp}."}" },
          { q: "Où regarder le replay de ce #{cp} entre #{h} et #{a} ?", a: "Le replay intégral de #{h} - #{a} (#{score}) est disponible sur l'espace abonné de #{ch} dans les heures suivant la rencontre." },
          { q: "Quelle équipe a dominé le match #{h} - #{a} ?", a: "#{winner ? "#{winner} s'est imposé #{score} dans ce #{cp}, confirmant sa maîtrise sur #{match.home_score.to_i > match.away_score.to_i ? a : h}." : "Ce nul #{score} entre #{h} et #{a} reflète un équilibre entre les deux équipes en #{cp}."}" }
        ],
        # 12
        [
          { q: "Quel était le score à la mi-temps de #{h} - #{a} ?", a: "Le score final du match #{h} - #{a} en #{cp} est #{score}. Le détail mi-temps est disponible dans le résumé sur cette page." },
          { q: "Ce #{cp} #{h} - #{a} avait-il lieu en semaine ou le week-end ?", a: "La rencontre #{h} - #{a} (#{score} en #{cp}) s'est disputée le #{date_label}. Retrouvez le programme complet sur Coup d'Envoi TV." },
          { q: "#{winner ? "Combien de victoires consécutives pour #{winner} ?" : "Combien de matchs nuls #{h} et #{a} ont-ils cette saison ?"}", a: "#{winner ? "Cette victoire #{score} est un nouveau succès pour #{winner} en #{cp}. Retrouvez les statistiques complètes sur la page de l'équipe." : "Ce nul #{score} s'ajoute au bilan de #{h} et #{a} en #{cp} 2025-2026. Statistiques complètes sur leurs pages d'équipes."}" }
        ],
        # 13
        [
          { q: "#{h} - #{a} : y avait-il des cartons dans ce match ?", a: "Retrouvez l'ensemble des faits de jeu de #{h} - #{a} (#{score} en #{cp}) dans la timeline des événements sur cette page." },
          { q: "Ce résultat #{score} confirme-t-il la hiérarchie en #{cp} ?", a: "#{winner ? "#{winner} s'est imposé #{score} face à #{match.home_score.to_i > match.away_score.to_i ? a : h} en #{cp}. Le classement est disponible sur notre page dédiée." : "Ce nul #{score} entre #{h} et #{a} ne bouscule pas forcément la hiérarchie en #{cp}. Consultez le classement mis à jour."}" },
          { q: "Puis-je revoir #{h} - #{a} gratuitement ?", a: "Le replay complet est réservé aux abonnés #{ch}. Des extraits peuvent être disponibles sur les réseaux sociaux officiels des clubs." }
        ],
        # 14
        [
          { q: "#{h} joue-t-il bien à domicile cette saison en #{cp} ?", a: "Retrouvez le bilan à domicile de #{h} sur sa page d'équipe. Ce match face à #{a} s'est terminé #{score} en #{cp}." },
          { q: "#{a} avait-il des absents pour ce #{cp} contre #{h} ?", a: "Les informations sur les absents et blessés sont disponibles sur la page du match. Score final : #{h} #{score} #{a} en #{cp}." },
          { q: "Quel était le contexte de #{h} - #{a} avant la rencontre ?", a: "#{h} recevait #{a} dans le cadre de la #{cp} 2025-2026. Le match s'est conclu sur le score de #{score}. Résumé complet disponible ci-dessus." }
        ],
        # 15
        [
          { q: "#{h} et #{a} se sont-ils déjà affrontés cette saison ?", a: "Les confrontations directes entre #{h} et #{a} sont disponibles dans la section head-to-head sur cette page. Score de ce match : #{score} en #{cp}." },
          { q: "#{winner ? "#{winner} monte-t-il au classement #{cp} après ce #{score} ?" : "Ce nul #{score} en #{cp} pénalise-t-il #{h} ou #{a} ?"}", a: "#{winner ? "Oui, cette victoire #{score} est positive pour #{winner} au classement #{cp}. Retrouvez le classement complet sur notre page dédiée." : "Un point chacun pour #{h} et #{a} après ce nul #{score} en #{cp}. Classement disponible sur notre page dédiée."}" },
          { q: "Résumé de #{h} - #{a} : où le lire ?", a: "Le résumé éditorial de #{h} - #{a} (#{score} en #{cp}) est disponible sur cette page, rédigé par notre équipe après le coup de sifflet final." }
        ],
        # 16
        [
          { q: "#{h} - #{a} : ce match de #{cp} était-il décisif ?", a: "#{winner ? "La victoire de #{winner} sur le score de #{score} en #{cp} pèse dans la course à la qualification ou au titre." : "Ce nul #{score} entre #{h} et #{a} en #{cp} peut avoir son importance selon la situation au classement."} Détails sur la page compétition." },
          { q: "Quelle note donner à ce #{cp} entre #{h} et #{a} ?", a: "#{winner ? "#{winner} s'est imposé #{score} dans une rencontre de #{cp} finalement maîtrisée." : "Un match équilibré entre #{h} et #{a} en #{cp}, ponctué d'un nul #{score}."} Retrouvez le résumé complet ci-dessus." },
          { q: "À quelle heure s'est terminé #{h} - #{a} ?", a: "Le match #{h} - #{a} a débuté et s'est conclu lors de la journée du #{date_label} en #{cp}. Score final : #{score}." }
        ],
        # 17
        [
          { q: "#{h} - #{a} : victoire, défaite ou nul pour #{h} ?", a: "#{match.home_score.to_i > match.away_score.to_i ? "Victoire de #{h} sur le score de #{score} face à #{a} en #{cp}." : match.home_score.to_i < match.away_score.to_i ? "Défaite de #{h} #{score} face à #{a} en #{cp}." : "Match nul #{score} pour #{h} contre #{a} en #{cp}."}" },
          { q: "Où voir les temps forts de #{h} - #{a} en #{cp} ?", a: "Les temps forts de #{h} - #{a} (#{score}) sont disponibles en replay sur #{ch} et résumés sur cette page." },
          { q: "#{cp} : quel bilan pour #{h} et #{a} cette saison ?", a: "Retrouvez les statistiques complètes de #{h} et de #{a} en #{cp} 2025-2026 sur leurs pages d'équipes respectives. Dernier résultat : #{h} #{score} #{a}." }
        ],
        # 18
        [
          { q: "#{h} - #{a} s'est fini comment exactement ?", a: "#{winner ? "#{winner} a remporté ce match de #{cp} sur le score de #{score}." : "Le match #{h} - #{a} en #{cp} s'est terminé sur un match nul #{score}."}" },
          { q: "Ce #{cp} entre #{h} et #{a} était-il retransmis sur #{ch} ?", a: "Oui, #{h} - #{a} (#{score}) était diffusé sur #{ch} dans le cadre de la #{cp} 2025-2026. Le replay est disponible pour les abonnés." },
          { q: "Quel est le palmarès de #{h} contre #{a} en #{cp} ?", a: "L'historique des confrontations entre #{h} et #{a} est disponible dans la section head-to-head sur cette page. Dernier résultat connu : #{score}." }
        ],
        # 19
        [
          { q: "Score : #{h} #{score} #{a} — est-ce bien le résultat officiel ?", a: "Oui, #{score} est le score officiel du match #{h} - #{a} en #{cp} disputé le #{date_label}." },
          { q: "Après #{score}, qui est en meilleure position en #{cp} ?", a: "#{winner ? "#{winner} tire profit de ce #{score} en #{cp}. Consultez le classement complet sur notre page dédiée." : "Après ce nul #{score}, #{h} et #{a} progressent à égalité en #{cp}. Classement disponible sur notre page."}" },
          { q: "Le résumé de #{h} - #{a} est-il disponible en français ?", a: "Oui, le résumé de #{h} - #{a} (#{score} en #{cp}) est rédigé en français sur cette page. Replay intégral sur #{ch} pour les abonnés." }
        ]
      ]
      finished_sets[match.id % finished_sets.size]
    else
      upcoming_sets = [
        [
          { q: "Sur quelle chaîne voir #{h} - #{a} ?", a: "Le match #{h} - #{a} est diffusé sur #{ch}. Vérifiez votre abonnement ou accédez à l'application officielle pour regarder en direct." },
          { q: "À quelle heure commence #{h} - #{a} ?", a: "Le coup d'envoi de #{h} - #{a} est prévu à #{hr} le #{date_label} (heure française)." },
          { q: "Comment voir #{h} - #{a} en streaming ?", a: "Pour regarder #{h} - #{a} en streaming légal, connectez-vous à l'application officielle de #{ch} avec un abonnement actif." }
        ],
        [
          { q: "Où regarder #{h} contre #{a} en direct ?", a: "#{h} - #{a} est à suivre en direct sur #{ch} à #{hr}. Disponible sur votre télévision, ordinateur et smartphone." },
          { q: "#{h} - #{a} : c'est à quelle heure ?", a: "Coup d'envoi fixé à #{hr} le #{date_label}. Ce match de #{cp} est diffusé sur #{ch}." },
          { q: "Peut-on regarder #{h} - #{a} sans abonnement ?", a: "#{ch} est une chaîne payante. Un abonnement est nécessaire pour accéder à la diffusion en direct de #{h} - #{a}." }
        ],
        [
          { q: "#{h} vs #{a} : quelle chaîne TV ?", a: "Ce match de #{cp} est diffusé sur #{ch} à #{hr}. Allumez votre téléviseur ou ouvrez l'application pour ne pas rater le coup d'envoi." },
          { q: "Streaming #{h} - #{a} : comment faire ?", a: "Rendez-vous sur l'application ou le site de #{ch} avec vos identifiants d'abonné. Le direct démarre à #{hr} heure française." },
          { q: "#{h} - #{a} est-il disponible sur mobile ?", a: "Oui, #{ch} propose une application mobile pour iOS et Android qui permet de suivre #{h} - #{a} en direct depuis votre smartphone ou tablette." }
        ],
        [
          { q: "Comment regarder #{h} - #{a} le #{date_label} ?", a: "Le match #{h} - #{a} est diffusé à #{hr} sur #{ch}. Accédez au direct via la télévision, l'application mobile ou le site officiel du diffuseur." },
          { q: "#{h} - #{a} en #{cp} : heure et chaîne ?", a: "Coup d'envoi à #{hr} sur #{ch}. Il s'agit d'une rencontre officielle de #{cp} pour la saison 2025-2026." },
          { q: "Y a-t-il un replay pour #{h} - #{a} ?", a: "Oui, #{ch} propose généralement le replay quelques heures après la fin du match pour ses abonnés." }
        ],
        [
          { q: "Où voir #{h} - #{a} en direct ce soir ?", a: "#{h} - #{a} est en direct sur #{ch} à #{hr}. Abonnez-vous ou connectez-vous si vous êtes déjà client." },
          { q: "#{a} joue contre #{h} : à quelle heure ?", a: "La rencontre #{h} - #{a} débute à #{hr} dans le cadre de la #{cp}. Diffusion assurée par #{ch}." },
          { q: "Est-ce que #{h} - #{a} est sur #{ch} ?", a: "Oui, #{ch} diffuse bien ce match de #{cp} entre #{h} et #{a} à #{hr}. Vérifiez votre abonnement avant le coup d'envoi." }
        ],
        [
          { q: "#{cp} : sur quelle chaîne est #{h} - #{a} ?", a: "Ce match de #{cp} est sur #{ch} à #{hr}. Accédez au direct depuis votre box TV ou l'application officielle." },
          { q: "Heure du match #{h} contre #{a} ?", a: "#{h} et #{a} s'affrontent à #{hr} le #{date_label}. Le match est à suivre sur #{ch}." },
          { q: "Comment accéder au direct de #{h} - #{a} depuis l'étranger ?", a: "Depuis l'étranger, connectez-vous à l'application #{ch} avec votre abonnement. Certaines restrictions géographiques peuvent s'appliquer selon votre pays." }
        ],
        [
          { q: "Puis-je regarder #{h} - #{a} sur ma smart TV ?", a: "Oui, #{ch} est disponible sur la plupart des smart TV. Téléchargez l'application ou accédez directement depuis votre box opérateur pour suivre #{h} - #{a} à #{hr}." },
          { q: "#{h} - #{a} : c'est quand et sur quelle chaîne ?", a: "Le #{date_label} à #{hr} sur #{ch}. Une rencontre de #{cp} à ne pas manquer." },
          { q: "Le match #{h} vs #{a} est-il gratuit ?", a: "#{ch} est accessible sur abonnement payant. Sans abonnement, il n'est pas possible de suivre #{h} - #{a} en direct légalement." }
        ],
        [
          { q: "Diffusion #{h} - #{a} : tout ce qu'il faut savoir", a: "#{h} - #{a} est diffusé le #{date_label} à #{hr} sur #{ch} dans le cadre de la #{cp}. Accès via télévision, ordinateur ou application mobile avec abonnement." },
          { q: "#{h} joue à quelle heure contre #{a} ?", a: "#{h} entre en jeu à #{hr} face à #{a}. Match à suivre en direct sur #{ch}." },
          { q: "Où trouver le programme complet de #{cp} ?", a: "Retrouvez tous les matchs de #{cp} en cours et à venir sur Coup d'Envoi TV, avec les horaires et les chaînes de diffusion mis à jour en temps réel." }
        ],
        [
          { q: "Sur quel canal regarder #{h} - #{a} ?", a: "#{h} - #{a} est sur #{ch} à #{hr}. Cherchez la chaîne dans votre guide TV ou connectez-vous à l'application officielle." },
          { q: "Ce match de #{cp} est-il en exclusivité sur #{ch} ?", a: "Oui, #{ch} détient les droits de diffusion de ce match #{h} - #{a} en #{cp}. Aucune autre chaîne ne le retransmet en France." },
          { q: "Comment voir #{h} - #{a} depuis mon téléphone ?", a: "Téléchargez l'application #{ch} sur l'App Store ou Google Play, connectez-vous avec vos identifiants, et suivez #{h} - #{a} en direct à #{hr}." }
        ],
        [
          { q: "#{h} - #{a} : à quelle heure et sur quelle plateforme ?", a: "Rendez-vous à #{hr} sur #{ch} pour ce match de #{cp}. Streaming disponible sur l'application et le site officiel du diffuseur." },
          { q: "Quel abonnement pour voir #{h} contre #{a} ?", a: "Un abonnement #{ch} est nécessaire pour suivre #{h} - #{a} en direct. Les offres sont disponibles directement sur le site ou via votre opérateur internet." },
          { q: "Le match #{h} - #{a} sera-t-il en replay ?", a: "#{ch} propose le replay de ses matchs pour les abonnés après le coup de sifflet final. #{h} - #{a} devrait être disponible en différé peu après la fin de la rencontre." }
        ],
        [
          { q: "Qui diffuse #{h} - #{a} en France ?", a: "C'est #{ch} qui retransmet #{h} - #{a} en France, à #{hr} dans le cadre de la #{cp}." },
          { q: "#{h} - #{a} commence à quelle heure exactement ?", a: "Le coup d'envoi officiel est prévu à #{hr} heure française le #{date_label}." },
          { q: "Comment s'abonner à #{ch} pour voir #{cp} ?", a: "Rendez-vous sur le site officiel de #{ch} pour découvrir les offres d'abonnement. Vous pouvez aussi passer par votre fournisseur internet (Orange, Free, SFR, Bouygues) pour des tarifs groupés." }
        ],
        [
          { q: "#{a} - #{h} ou #{h} - #{a} : quelle est l'équipe à domicile ?", a: "Dans cette rencontre de #{cp}, c'est #{h} qui reçoit #{a} à #{hr} sur #{ch}." },
          { q: "Le match #{h} vs #{a} est-il en direct ou en différé ?", a: "#{ch} diffuse #{h} - #{a} en direct à #{hr}. Le replay sera disponible pour les abonnés après la fin de la rencontre." },
          { q: "Où voir les stats en direct de #{h} - #{a} ?", a: "Les statistiques en temps réel de #{h} - #{a} sont disponibles sur Coup d'Envoi TV pendant toute la durée du match." }
        ],
        # 12
        [
          { q: "#{h} - #{a} : peut-on regarder depuis une télévision connectée ?", a: "Oui, #{ch} est disponible sur les principales smart TV (Samsung, LG, Sony) ainsi que via Apple TV, Chromecast et Amazon Fire TV. Connectez-vous avec vos identifiants avant #{hr}." },
          { q: "Ce match de #{cp} est-il important pour le classement ?", a: "#{h} et #{a} s'affrontent dans le cadre de la #{cp} 2025-2026. Chaque point compte — retrouvez le classement mis à jour sur notre page dédiée." },
          { q: "À quel endroit se joue #{h} - #{a} ?", a: "#{h} reçoit #{a} à domicile pour ce match de #{cp} diffusé à #{hr} sur #{ch}." }
        ],
        # 13
        [
          { q: "#{h} contre #{a} : y a-t-il une retransmission gratuite ?", a: "Ce match de #{cp} est diffusé sur #{ch}, une chaîne à accès payant. Aucune diffusion gratuite n'est prévue en France pour #{h} - #{a}." },
          { q: "Quelle application utiliser pour voir #{h} - #{a} en streaming ?", a: "L'application officielle de #{ch} (disponible sur iOS et Android) vous permet de suivre #{h} - #{a} en direct à #{hr} avec votre abonnement." },
          { q: "#{h} - #{a} est diffusé à quelle heure en France ?", a: "Le coup d'envoi de #{h} - #{a} est fixé à #{hr}, heure de Paris. Match de #{cp} à suivre sur #{ch}." }
        ],
        # 14
        [
          { q: "Comment être sûr de ne pas rater #{h} - #{a} ?", a: "Notez l'heure : #{hr} le #{date_label} sur #{ch}. Vous pouvez aussi activer les notifications sur l'application #{ch} pour un rappel avant le coup d'envoi." },
          { q: "#{h} - #{a} : le match est-il en HD sur #{ch} ?", a: "#{ch} diffuse ses matchs en haute définition pour les abonnés. Assurez-vous d'avoir une connexion stable pour profiter de #{h} - #{a} en HD à #{hr}." },
          { q: "Peut-on voir #{h} vs #{a} en famille ce #{date_label} ?", a: "Absolument - rendez-vous à #{hr} sur #{ch} pour ce #{cp}. L'application permet aussi de caster le match sur votre télévision depuis un smartphone." }
        ],
        # 15
        [
          { q: "#{h} reçoit #{a} : c'est sur quelle chaîne ?", a: "Ce match à domicile de #{h} contre #{a} en #{cp} est diffusé sur #{ch} à #{hr}. Accès via télévision, box internet ou application mobile." },
          { q: "Y a-t-il un match #{cp} ce #{date_label} ?", a: "Oui, #{h} affronte #{a} en #{cp} à #{hr} sur #{ch}. Retrouvez le programme complet des matchs du jour sur Coup d'Envoi TV." },
          { q: "Le direct de #{h} - #{a} commence à #{hr} : est-ce l'heure du coup d'envoi ?", a: "Oui, #{hr} est l'heure officielle du coup d'envoi. Les chaînes comme #{ch} diffusent généralement les avant-matchs quelques minutes avant." }
        ],
        # 16
        [
          { q: "#{h} vs #{a} en #{cp} : qui est favori ?", a: "Ce match de #{cp} entre #{h} et #{a} s'annonce ouvert. Retrouvez les prochains matchs et le classement des deux équipes sur leurs pages respectives." },
          { q: "Puis-je enregistrer #{h} - #{a} sur mon décodeur ?", a: "Si vous recevez #{ch} via votre box TV (Orange, Free, SFR, Bouygues), vous pouvez programmer l'enregistrement de #{h} - #{a} depuis votre guide des programmes." },
          { q: "Le match #{h} - #{a} de #{cp} sera-t-il commenté en français ?", a: "Oui, #{ch} propose une diffusion commentée en français. Coup d'envoi à #{hr} pour cette rencontre de #{cp}." }
        ],
        # 17
        [
          { q: "Où acheter des billets pour voir #{h} - #{a} au stade ?", a: "Les billets pour #{h} - #{a} sont disponibles sur le site officiel du club domicile. Pour suivre le match depuis chez vous, c'est sur #{ch} à #{hr}." },
          { q: "#{h} - #{a} : c'est quelle journée de #{cp} ?", a: "Ce match compte pour la saison 2025-2026 de #{cp}. Retrouvez le calendrier complet sur la page de la compétition." },
          { q: "Comment regarder #{cp} sans se ruiner ?", a: "#{ch} propose plusieurs formules d'abonnement pour suivre la #{cp}. Vérifiez les offres groupées avec votre fournisseur internet pour obtenir le meilleur tarif." }
        ],
        # 18
        [
          { q: "#{h} - #{a} est-il retransmis à l'international ?", a: "En France, ce match de #{cp} est diffusé sur #{ch} à #{hr}. Les droits à l'international varient selon les pays - vérifiez les diffuseurs locaux si vous êtes à l'étranger." },
          { q: "Quelle est la forme récente de #{h} avant ce match ?", a: "Retrouvez le bilan récent de #{h} et de #{a} sur leurs pages d'équipes respectives. Le match est à suivre sur #{ch} à #{hr} en #{cp}." },
          { q: "#{h} - #{a} : les deux équipes se connaissent bien ?", a: "Retrouvez les confrontations directes entre #{h} et #{a} sur cette page. Le prochain rendez-vous est fixé à #{hr} sur #{ch} en #{cp}." }
        ],
        # 19
        [
          { q: "Sur quelle fréquence trouver #{ch} sur ma box ?", a: "Le numéro de canal de #{ch} varie selon votre opérateur. Cherchez #{ch} dans votre guide TV ou sur l'application de votre box pour suivre #{h} - #{a} à #{hr}." },
          { q: "#{h} - #{a} : le match risque-t-il d'être reporté ?", a: "Aucun report n'est signalé pour #{h} - #{a}. Le coup d'envoi reste prévu à #{hr} sur #{ch} dans le cadre de la #{cp}." },
          { q: "C'est quoi #{cp} : un championnat ou une coupe ?", a: "#{cp} est l'une des compétitions majeures du calendrier footballistique européen. #{h} et #{a} s'y affrontent le #{date_label} à #{hr} sur #{ch}." }
        ]
      ]
      upcoming_sets[match.id % upcoming_sets.size]
    end
  end
end
