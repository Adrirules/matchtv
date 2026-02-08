module SeoHelper
  def meta_title(title)
    content_for(:title) { title }
  end

  def meta_description(description)
    content_for(:meta_description) { description } # Vérifie bien si c'est :description ou :meta_description dans ton layout
  end

  def generate_match_seo(match)
    templates = [
      {
        title: "⚽ %{match} : Chaîne, Heure et Direct | Coup d'Envoi",
        desc: "Sur quelle chaîne et à quelle heure regarder %{match} ? Découvrez le programme TV complet, l'horaire de diffusion et les compos d'équipes."
      },
      {
        title: "📺 %{match} : Quel programme TV pour le match ce soir ?",
        desc: "Diffusion %{match} : à quelle heure et sur quelle chaîne télé ? Retrouvez notre guide complet pour ne rien rater du match en direct."
      },
      {
        title: "⌚ %{match} : Heure de diffusion, chaîne et streaming",
        desc: "Besoin de l'horaire du match %{match} ? Voici la chaîne TV, le coup d'envoi et toutes les infos pour suivre la diffusion en live."
      }
    ]

    # Sélection stable basée sur l'ID
    template = templates[match.id % templates.size]
    match_name = "#{match.home_team} - #{match.away_team}"

    # On utilise tes fonctions existantes pour envoyer les données au layout
    meta_title(template[:title] % { match: match_name })
    meta_description(template[:desc] % { match: match_name })
  end
end
