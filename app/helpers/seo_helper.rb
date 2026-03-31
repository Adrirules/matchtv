module SeoHelper
  def meta_title(title)
    content_for(:title) { title }
  end

  def meta_description(description)
    content_for(:meta_description) { description }
  end

  def generate_match_seo(match)
    match_name = "#{match.home_team} - #{match.away_team}"

    if match.finished? && match.has_score?
      score = "#{match.home_score}-#{match.away_score}"
      comp  = match.competition

      winner_phrase = if match.home_score.to_i > match.away_score.to_i
        "#{match.home_team} s'impose #{score}"
      elsif match.away_score.to_i > match.home_score.to_i
        "#{match.away_team} s'impose #{score}"
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
      meta_title(template[:title] % { h: match.home_team, a: match.away_team, score: score, comp: comp })
      meta_description(template[:desc] % { h: match.home_team, a: match.away_team, score: score, comp: comp, winner: winner_phrase })
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
    h   = match.home_team
    a   = match.away_team
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
    h   = match.home_team
    a   = match.away_team
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
        ]
      ]
      upcoming_sets[match.id % upcoming_sets.size]
    end
  end
end
