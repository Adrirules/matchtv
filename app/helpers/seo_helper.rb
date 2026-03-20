module SeoHelper
  def meta_title(title)
    content_for(:title) { title }
  end

  def meta_description(description)
    content_for(:meta_description) { description }
  end

  def generate_match_seo(match)
    templates = [
      {
        title: "%{match} : Chaîne TV, Heure et Direct | Coup d'Envoi TV",
        desc: "Sur quelle chaîne et à quelle heure regarder %{match} ? Programme TV complet, horaire de diffusion et infos match en direct."
      },
      {
        title: "%{match} : sur quelle chaîne voir le match ? | Coup d'Envoi TV",
        desc: "Diffusion %{match} : heure de coup d'envoi et chaîne TV. Notre guide complet pour ne rien rater du match en direct ou en streaming."
      },
      {
        title: "%{match} - Heure, chaîne TV et streaming | Coup d'Envoi TV",
        desc: "Tout savoir sur la diffusion de %{match} : heure de coup d'envoi, chaîne TV et accès streaming légal. Mis à jour en temps réel."
      },
      {
        title: "Où voir %{match} ? Chaîne et heure | Coup d'Envoi TV",
        desc: "Vous cherchez sur quelle chaîne passe %{match} ? Retrouvez l'heure de diffusion, la chaîne TV et le lien streaming officiel."
      },
      {
        title: "%{match} en direct : chaîne TV et coup d'envoi | Coup d'Envoi TV",
        desc: "%{match} : découvrez à quelle heure et sur quelle chaîne regarder ce match en direct. Streaming légal disponible sur l'application officielle."
      },
      {
        title: "%{match} : programme TV et streaming | Coup d'Envoi TV",
        desc: "Ne ratez pas %{match} ! Heure de coup d'envoi, chaîne TV et accès streaming. Toutes les infos pour suivre le match en direct."
      }
    ]

    template = templates[match.id % templates.size]
    match_name = "#{match.home_team} - #{match.away_team}"

    meta_title(template[:title] % { match: match_name })
    meta_description(template[:desc] % { match: match_name })
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
      ]
    ]

    variations[match.id % variations.size]
  end
end
