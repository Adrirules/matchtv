class MatchSummaryService
  GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
  MODEL        = "llama-3.3-70b-versatile"

  # Reverse map : nom de compétition → league_id (pour requêter les standings en DB)
  COMPETITION_LEAGUE_ID = FootballApiService::SUPPORTED_LEAGUES.invert.freeze

  # Mots interdits injectés dans chaque prompt pour casser les patterns détectables par Google
  BANNED_PHRASES = [
    "match passionnant", "belle affiche", "rendez-vous incontournable",
    "conditions météo défavorables", "il va pleuvoir", "beau match",
    "duel au sommet", "choc des titans", "rencontre cruciale"
  ].freeze

  # ─────────────────────────────────────────────────────────────────────
  # POINTS D'ENTRÉE PUBLICS
  # ─────────────────────────────────────────────────────────────────────

  def self.generate(match)
    return match.summary if match.summary.present?
    return nil unless match.finished? && match.home_score.present?
    call_groq(build_summary_prompt(match), match, max_tokens: 260)
  end

  def self.generate_preview(match)
    return match.preview if match.preview.present?
    return nil if match.finished?
    call_groq(build_preview_prompt(match), match, max_tokens: 360, field: :preview)
  end

  def self.generate_batch(matches)
    matches.each { |m| generate(m); sleep 2.1 }
  end

  def self.generate_previews_batch(matches)
    matches.each { |m| generate_preview(m); sleep 2.1 }
  end

  private

  # ─────────────────────────────────────────────────────────────────────
  # APPEL GROQ
  # ─────────────────────────────────────────────────────────────────────

  def self.call_groq(prompt, match, max_tokens:, field: :summary)
    response = Faraday.post(GROQ_API_URL) do |req|
      req.headers["Authorization"] = "Bearer #{ENV['GROQ_API_KEY']}"
      req.headers["Content-Type"]  = "application/json"
      req.body = {
        model:       MODEL,
        messages:    [{ role: "user", content: prompt }],
        max_tokens:  max_tokens,
        temperature: 0.7
      }.to_json
    end

    unless response.success?
      body = response.body
      puts "  💥 HTTP #{response.status} pour match #{match.id}: #{body.truncate(300)}"
      Rails.logger.error("[MatchSummaryService] HTTP #{response.status} match #{match.id}: #{body}")
      return :daily_limit_reached if response.status == 429 && body.include?("tokens per day")
      return nil
    end

    text = JSON.parse(response.body).dig("choices", 0, "message", "content")&.strip
    match.update_column(field, text) if text.present?
    text

  rescue => e
    puts "  💥 EXCEPTION #{e.class} pour match #{match.id}: #{e.message}"
    Rails.logger.error("[MatchSummaryService] Erreur match #{match.id}: #{e.message}")
    nil
  end

  # ─────────────────────────────────────────────────────────────────────
  # DONNÉES CONTEXTUELLES — DB ONLY, 0 APPEL API
  # ─────────────────────────────────────────────────────────────────────

  # Position au classement pour une équipe dans une compétition (depuis la table standings en DB)
  def self.standing_position(team_api_id, competition_name)
    return nil if team_api_id.nil?
    league_id = COMPETITION_LEAGUE_ID[competition_name]
    return nil unless league_id
    standing = Standing.for_league(league_id)
    return nil unless standing&.data
    rows = standing.data.dig(0, "league", "standings")&.flatten || []
    row  = rows.find { |r| r.dig("team", "id") == team_api_id }
    row ? row["rank"] : nil
  rescue
    nil
  end

  # Forme récente depuis la DB (V/N/D, du plus récent au plus ancien)
  def self.recent_form(team_api_id, count: 5, before: nil)
    return [] if team_api_id.nil?
    q = Match.where("home_team_api_id = :id OR away_team_api_id = :id", id: team_api_id)
             .where(status: Match::FINISHED_STATUSES)
             .order(start_time: :desc)
             .limit(count)
    q = q.where("start_time < ?", before) if before
    q.map do |m|
      home = m.home_team_api_id == team_api_id
      won  = home ? m.home_score > m.away_score  : m.away_score > m.home_score
      draw = m.home_score == m.away_score
      draw ? "N" : (won ? "V" : "D")
    end
  rescue
    []
  end

  # Dernier H2H depuis la DB (pas d'appel API)
  def self.last_h2h(home_api_id, away_api_id)
    return nil if home_api_id.nil? || away_api_id.nil?
    Match.where(
      "(home_team_api_id = :a AND away_team_api_id = :b) OR " \
      "(home_team_api_id = :b AND away_team_api_id = :a)",
      a: home_api_id, b: away_api_id
    ).where(status: Match::FINISHED_STATUSES)
     .order(start_time: :desc)
     .first
  rescue
    nil
  end

  # "3V 1N 1D sur les 5 derniers matchs"
  def self.form_label(form)
    return nil if form.empty?
    w, d, l = form.count("V"), form.count("N"), form.count("D")
    parts = []
    parts << "#{w}V" if w > 0
    parts << "#{d}N" if d > 0
    parts << "#{l}D" if l > 0
    "#{parts.join(' ')} sur les #{form.size} derniers matchs"
  end

  # ─────────────────────────────────────────────────────────────────────
  # MÉTÉO — TRADUCTION EN IMPACT TERRAIN (pas en bulletin météo)
  # ─────────────────────────────────────────────────────────────────────

  def self.weather_instruction(weather)
    return "" if weather.blank?
    rain = weather =~ /pluie|rain|averses|bruine|shower/i
    wind = weather =~ /vent|wind|\d{2,3}\s*km/i
    cold = weather =~ /\b[0-5]°/
    heat = weather =~ /\b[3-9]\d°/

    if rain
      "Météo réelle : #{weather}. " \
      "INTERDIT d'écrire : 'il va pleuvoir', 'conditions météo défavorables', 'météo difficile'. " \
      "À la place, décris l'impact concret sur le jeu parmi ces options selon le contexte : " \
      "terrain lourd ou glissant, ballons qui dévient sur les frappes lointaines, " \
      "gardiens gênés sur les sorties aériennes, duels physiques avantagés par rapport aux combinaisons, " \
      "jeu direct et frappes de loin favorisés. Choisis l'impact le plus pertinent pour cette affiche spécifiquement."
    elsif wind
      "Météo réelle : #{weather}. " \
      "Ne dis pas 'vent fort' ou 'conditions météo'. " \
      "Traduis en impact footballistique : centres perturbés, jeu au sol favorisé, " \
      "coups de pied arrêtés aléatoires, frappes longue distance compromises."
    elsif cold
      "Météo réelle : #{weather}. Si pertinent en une demi-phrase max : terrain dur, gestion physique en fin de match."
    elsif heat
      "Météo réelle : #{weather}. Si pertinent : rythme réduit en seconde période, gestion physique des deux équipes."
    else
      ""
    end
  end

  # Chaîne notable ? (justifie une mention)
  def self.notable_channel?(diffusion)
    %w[Canal+ beIN DAZN RMC Amazon].any? { |c| diffusion.to_s.include?(c) }
  end

  # Ligne bannissement toujours injectée
  def self.banned_line
    "MOTS ET EXPRESSIONS INTERDITS (ne pas écrire, même paraphrasé) : #{BANNED_PHRASES.join(', ')}."
  end

  # ─────────────────────────────────────────────────────────────────────
  # BUILD PREVIEW PROMPT — 10 angles (match.id % 10)
  # ─────────────────────────────────────────────────────────────────────

  def self.build_preview_prompt(match)
    date_fr   = match.start_time.strftime("%d/%m/%Y à %Hh%M")
    diffusion = match.tv_channels.presence || "non diffusé en France"
    weather   = WeatherService.for_match(match)

    # Données DB
    pos_home  = standing_position(match.home_team_api_id, match.competition)
    pos_away  = standing_position(match.away_team_api_id, match.competition)
    form_home = recent_form(match.home_team_api_id, count: 5, before: match.start_time)
    form_away = recent_form(match.away_team_api_id, count: 5, before: match.start_time)
    h2h       = last_h2h(match.home_team_api_id, match.away_team_api_id)

    # Lignes contexte
    rank_line = if pos_home && pos_away
      "Classement actuel : #{match.home_team} #{pos_home}e, #{match.away_team} #{pos_away}e"
    elsif pos_home
      "Classement actuel : #{match.home_team} #{pos_home}e"
    elsif pos_away
      "Classement actuel : #{match.away_team} #{pos_away}e"
    end

    form_home_line = form_home.any? ? "Forme #{match.home_team} (5 derniers) : #{form_home.join} — #{form_label(form_home)}" : nil
    form_away_line = form_away.any? ? "Forme #{match.away_team} (5 derniers) : #{form_away.join} — #{form_label(form_away)}" : nil
    h2h_line = if h2h
      "Dernier face-à-face (#{h2h.start_time.strftime('%d/%m/%Y')}) : #{h2h.home_team} #{h2h.home_score}-#{h2h.away_score} #{h2h.away_team}"
    end

    ctx   = [rank_line, form_home_line, form_away_line, h2h_line].compact.join("\n")
    meteo = weather_instruction(weather)
    tmpl  = match.id % 10

    preview_template(tmpl, match.home_team, match.away_team, match.competition, date_fr, diffusion, ctx, meteo)
  end

  def self.preview_template(tmpl, home, away, comp, date_fr, diffusion, ctx, meteo)
    notable = notable_channel?(diffusion)
    ban     = banned_line

    case tmpl

    # ── 0 : Angle classement et enjeu — phrases courtes et percutantes ──
    when 0
      <<~P.strip
        Rédige un avant-match de football en français. Exactement 3 phrases. Pas de titre, pas de liste.
        Commence par l'enjeu au classement (Europe, maintien, titre). Cite les positions exactes si disponibles.
        Phrases courtes et percutantes — aucune ne dépasse 18 mots.
        #{notable ? "Intègre '#{diffusion}' naturellement dans une des phrases." : ""}
        #{meteo.present? ? meteo : ""}
        #{ban}

        Match : #{home} vs #{away} | #{comp} | #{date_fr}
        #{ctx}
      P

    # ── 1 : Angle forme et momentum — longueur variable, 4 phrases ──
    when 1
      <<~P.strip
        Rédige un avant-match de football en français. 4 phrases. Pas de titre.
        Commence sur la dynamique de l'une des équipes (série, rebond, momentum). Appuie-toi sur la forme récente.
        Varie la longueur des phrases : une très courte (< 8 mots), une longue (> 22 mots), deux moyennes.
        #{notable ? "Mentionne #{diffusion}." : ""}
        #{meteo.present? ? meteo : ""}
        #{ban}

        Match : #{home} vs #{away} | #{comp} | #{date_fr}
        #{ctx}
      P

    # ── 2 : Angle H2H et historique — 3 phrases, commence par l'histoire entre les clubs ──
    when 2
      <<~P.strip
        Rédige un avant-match de football en français. 3 phrases. Style chronique.
        Commence par ce que le dernier face-à-face entre ces deux équipes nous apprend (score, contexte, enjeu).
        Puis l'enjeu du match d'aujourd'hui. #{notable ? "Intègre #{diffusion}." : ""}
        Ne commence pas par '#{home}' ni '#{away}'.
        #{meteo.present? ? meteo : ""}
        #{ban}

        Match : #{home} vs #{away} | #{comp} | #{date_fr}
        #{ctx}
      P

    # ── 3 : Angle météo/terrain — la météo est le fil conducteur si notable ──
    when 3
      if meteo.present?
        <<~P.strip
          Rédige un avant-match de football en français. 3 phrases. Commence directement sur l'affiche.
          La météo est l'élément central de cet avant-match : #{meteo}
          Deuxième phrase = l'enjeu sportif. Troisième phrase = #{notable ? "diffusion #{diffusion}" : "contexte au classement"}.
          Inclure obligatoirement une phrase de moins de 10 mots et une de plus de 20 mots.
          #{ban}

          Match : #{home} vs #{away} | #{comp} | #{date_fr}
          #{ctx}
        P
      else
        <<~P.strip
          Rédige un avant-match de football en français. 3 phrases. Angle tactique.
          Quelle équipe est avantagée par le contexte (domicile, classement, forme) ? Argumente.
          #{notable ? "Mentionne #{diffusion}." : ""}
          Commence par une phrase interrogative ou affirmative forte (pas un nom d'équipe).
          #{ban}

          Match : #{home} vs #{away} | #{comp} | #{date_fr}
          #{ctx}
        P
      end

    # ── 4 : Angle avantage domicile/extérieur — 3-4 phrases ──
    when 4
      <<~P.strip
        Rédige un avant-match de football en français. 3 à 4 phrases. Pas de liste.
        Mets en avant l'avantage ou le défi de jouer à domicile vs à l'extérieur comme facteur clé.
        Appuie-toi sur la forme récente si disponible. #{notable ? "Inclus #{diffusion}." : ""}
        #{meteo.present? ? meteo : ""}
        #{ban}

        Match : #{home} (domicile) vs #{away} (extérieur) | #{comp} | #{date_fr}
        #{ctx}
      P

    # ── 5 : Angle chiffres bruts — 2 phrases denses, 2 données numériques minimum ──
    when 5
      <<~P.strip
        Rédige un avant-match de football en français. Exactement 2 phrases. Dense en données.
        Règle absolue : intégrer au moins 2 chiffres précis (classement, résultats récents, écart de points, score H2H).
        Style télégraphique. #{notable ? "Mentionne #{diffusion}." : ""}
        #{meteo.present? ? meteo : ""}
        #{ban}

        Match : #{home} vs #{away} | #{comp} | #{date_fr}
        #{ctx}
      P

    # ── 6 : Angle radio — 2 phrases sèches, style antenne ──
    when 6
      <<~P.strip
        Rédige un avant-match style flash radio : 2 phrases exactement.
        Phrase 1 = l'enjeu en moins de 15 mots. Phrase 2 = où regarder et un élément de contexte.
        #{meteo.present? ? "Glisse en fin de phrase 2 l'impact terrain (une demi-phrase max) : #{meteo}" : ""}
        Ne commence pas par '#{home}' ni '#{away}'.
        #{ban}

        Match : #{home} vs #{away} | #{comp} | #{date_fr}
        Diffusion : #{diffusion}
        #{ctx}
      P

    # ── 7 : Angle enjeu saison — 4 phrases, analyse contextuelle ──
    when 7
      <<~P.strip
        Rédige un avant-match de football en français. 4 phrases. Style analyse hebdomadaire.
        Explique ce que ce match représente dans la saison de chaque équipe (course au titre, maintien, qualification, prestige).
        Classement et forme si disponibles. #{notable ? "Mentionne #{diffusion}." : ""}
        #{meteo.present? ? meteo : ""}
        Phrases de longueur variée — alterne court et long.
        #{ban}

        Match : #{home} vs #{away} | #{comp} | #{date_fr}
        #{ctx}
      P

    # ── 8 : Angle surprise — quelle équipe peut créer l'upset ? ──
    when 8
      <<~P.strip
        Rédige un avant-match de football en français. 3 phrases.
        Commence par la question implicite : quelle équipe peut créer la surprise ?
        Identifie l'équipe favorite et celle susceptible de renverser la tendance. Appuie-toi sur la forme.
        #{notable ? "Mentionne #{diffusion}." : ""}
        #{meteo.present? ? meteo : ""}
        #{ban}

        Match : #{home} vs #{away} | #{comp} | #{date_fr}
        #{ctx}
      P

    # ── 9 : Angle contexte large — ne commence pas par un nom d'équipe ──
    when 9
      <<~P.strip
        Rédige un avant-match de football en français. 3 à 4 phrases.
        N'commence pas par '#{home}' ni '#{away}' ni 'Ce soir' ni 'Le match'.
        Ouvre sur le contexte de la #{comp} cette saison, puis centre sur l'enjeu précis de cette affiche.
        #{notable ? "Intègre #{diffusion} naturellement." : ""}
        #{meteo.present? ? meteo : ""}
        #{ban}

        Match : #{home} vs #{away} | #{comp} | #{date_fr}
        #{ctx}
      P

    end
  end

  # ─────────────────────────────────────────────────────────────────────
  # BUILD SUMMARY PROMPT — 8 angles (match.id % 8)
  # ─────────────────────────────────────────────────────────────────────

  def self.build_summary_prompt(match)
    date_fr   = match.start_time.strftime("%d/%m/%Y")
    diffusion = match.tv_channels.presence || "non diffusé en France"
    score     = "#{match.home_score}-#{match.away_score}"
    gap       = (match.home_score - match.away_score).abs
    draw      = match.home_score == match.away_score
    big_win   = gap >= 3
    notable   = notable_channel?(diffusion)

    winner_text = if match.home_score > match.away_score
      "#{match.home_team} s'impose #{score}"
    elsif match.away_score > match.home_score
      "#{match.away_team} s'impose #{match.away_score}-#{match.home_score}"
    else
      "Match nul #{score}"
    end

    tmpl = match.id % 8
    summary_template(tmpl, match.home_team, match.away_team, match.competition,
                     date_fr, score, diffusion, winner_text, big_win, draw, gap, notable)
  end

  def self.summary_template(tmpl, home, away, comp, date_fr, score, diffusion, winner_text, big_win, draw, gap, notable)
    ban = banned_line

    case tmpl

    # ── 0 : Factuel direct — dépêche AFP, 2 phrases courtes ──
    when 0
      <<~P.strip
        Résume ce match de football en 2 phrases courtes. Style dépêche AFP.
        Commence par le score et le vainqueur. Deuxième phrase = ce que ce résultat signifie dans la compétition.
        #{notable ? "Mentionne #{diffusion} si c'est une grande affiche." : ""}
        Aucune exagération, aucune invention.
        #{ban}

        Match : #{home} #{score} #{away} | #{comp} | #{date_fr}
        Résultat : #{winner_text}
      P

    # ── 1 : Angle tournant — 2-3 phrases, ne commence pas par le score ──
    when 1
      context = if big_win
        "Victoire nette (#{gap} buts d'écart) : domination logique ou coup de théâtre ?"
      elsif draw
        "Match nul : qui s'en sort le mieux selon le contexte au classement ?"
      else
        "Victoire courte (1 but d'écart) : résultat serré, explique pourquoi c'est important."
      end
      <<~P.strip
        Résume ce match en 2 à 3 phrases. #{context}
        Ne commence pas par le score brut. Commence par le contexte ou l'enjeu.
        Varie la longueur des phrases : une courte (< 10 mots) et une longue (> 20 mots).
        #{notable ? "Intègre #{diffusion}." : ""}
        #{ban}

        Match : #{home} #{score} #{away} | #{comp} | #{date_fr}
        Résultat : #{winner_text}
      P

    # ── 2 : 2 phrases sèches, commence différemment ──
    when 2
      <<~P.strip
        Résume ce match en exactement 2 phrases. Directement les faits.
        Phrase 1 = résultat et ce qu'il change au classement ou en compétition.
        Phrase 2 = un détail marquant (ampleur du score, équipe dominante, ou diffusion si notable).
        INTERDIT de commencer par 'Ce match' ou le prénom d'un joueur inventé.
        #{ban}

        Match : #{home} #{score} #{away} | #{comp} | #{date_fr}
        Résultat : #{winner_text}
      P

    # ── 3 : Angle signification — commence par les conséquences, pas le score ──
    when 3
      <<~P.strip
        Résume ce match en 2 à 3 phrases. Commence par ce que ce résultat change dans la #{comp}.
        Puis donne le score. #{notable ? "Mentionne #{diffusion}." : ""}
        Aucun superlatif. Style magazine sportif sobre.
        #{ban}

        Match : #{home} #{score} #{away} | #{comp} | #{date_fr}
        Résultat : #{winner_text}
      P

    # ── 4 : Angle équipe battue ou tenue en échec ──
    when 4
      loser_context = draw ?
        "Match nul : analyse qui s'en sort mieux selon la position au classement." :
        "Que retient l'équipe battue ? Était-ce prévisible ou surprenant ?"
      <<~P.strip
        Résume ce match en 2 phrases. #{loser_context}
        Factuel, pas dramatique. Ne commence pas par 'Malgré' ni 'Hélas'.
        #{ban}

        Match : #{home} #{score} #{away} | #{comp} | #{date_fr}
        Résultat : #{winner_text}
      P

    # ── 5 : Style radio — 2 phrases, oral et direct ──
    when 5
      <<~P.strip
        Résume ce match style commentaire radio en 2 phrases exactes.
        Phrase 1 = ce qui s'est passé (< 15 mots). Phrase 2 = pourquoi c'est important.
        Ne commence pas par '#{home}' ni '#{away}'.
        #{ban}

        Match : #{home} #{score} #{away} | #{comp} | #{date_fr}
        Résultat : #{winner_text}
      P

    # ── 6 : Angle chiffre mis en avant ──
    when 6
      <<~P.strip
        Résume ce match en 2 à 3 phrases. Mets en avant au moins un chiffre au-delà du score.
        #{big_win ? "Insiste sur l'ampleur : #{gap} buts d'écart." : "Cherche un chiffre contextuel (numéro de journée si connu, série de matchs, etc.)."}
        Style synthétique. #{notable ? "Mentionne #{diffusion}." : ""}
        #{ban}

        Match : #{home} #{score} #{away} | #{comp} | #{date_fr}
        Résultat : #{winner_text}
      P

    # ── 7 : Commence par le contexte de la compétition, score en deuxième phrase ──
    when 7
      <<~P.strip
        Résume ce match en 3 phrases courtes. Structure imposée :
        1. Contexte de la #{comp} au moment de ce match.
        2. Le résultat brut.
        3. Ce que ça implique pour la suite.
        #{notable ? "Glisse #{diffusion} dans l'une des 3 phrases." : ""}
        0 invention de joueurs ou de statistiques non fournies.
        #{ban}

        Match : #{home} #{score} #{away} | #{comp} | #{date_fr}
        Résultat : #{winner_text}
      P

    end
  end
end
