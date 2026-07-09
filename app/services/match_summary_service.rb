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
    no_data = ctx.strip.empty? ? "Note : données de classement/forme non disponibles pour cette compétition. Reste sur l'enjeu général et la diffusion." : ""

    case tmpl

    # ── 0 : Angle classement — 3 phrases courtes (max 18 mots chacune) ──
    when 0
      <<~P.strip
        Tu es rédacteur football. Rédige un avant-match en français. Exactement 3 phrases. Pas de titre.
        Règle absolue de longueur : chaque phrase doit contenir entre 6 et 16 mots — pas plus, pas moins.
        Commence par l'enjeu au classement (Europe, maintien, titre). Cite les positions exactes si disponibles.
        #{notable ? "Intègre '#{diffusion}' dans l'une des phrases." : ""}
        #{meteo.present? ? meteo : ""}
        #{ban}
        #{no_data}

        EXEMPLE DE SORTIE (adapte aux vraies données, ne copie pas les équipes) :
        "Lens (6e) reçoit Nantes (14e) à Bollaert ce soir. Les Sang et Or veulent verrouiller la 6e place. Tout se joue sur DAZN à 21h."

        Match : #{home} vs #{away} | #{comp} | #{date_fr}
        #{ctx}
      P

    # ── 1 : Angle momentum — 4 phrases, longueur délibérément variable ──
    when 1
      <<~P.strip
        Tu es rédacteur football. Rédige un avant-match en français. Exactement 4 phrases. Pas de titre.
        Commence sur la dynamique récente de l'une des équipes (série, rebond après défaite, momentum).
        Contrainte de longueur : 1 phrase très courte (4-7 mots), 1 phrase longue (25-35 mots), 2 phrases moyennes.
        #{notable ? "Mentionne #{diffusion}." : ""}
        #{meteo.present? ? meteo : ""}
        #{ban}
        #{no_data}

        EXEMPLE DE SORTIE (adapte aux vraies données) :
        "Monaco enchaîne. Après trois victoires consécutives, les hommes d'Hütter débarquent à Lyon avec l'ambition de consolider leur troisième place, à seulement deux points du podium cette saison. Lyon, sans victoire depuis quatre matchs, cherche à relancer une saison devenue compliquée. Le choc est sur DAZN."

        Match : #{home} vs #{away} | #{comp} | #{date_fr}
        #{ctx}
      P

    # ── 2 : Angle H2H — commence par le dernier face-à-face ──
    when 2
      <<~P.strip
        Tu es rédacteur football. Rédige un avant-match en français. Exactement 3 phrases. Pas de titre.
        Commence par ce que le dernier H2H entre ces équipes révèle. Ne commence pas par '#{home}' ni '#{away}'.
        Puis l'enjeu du match d'aujourd'hui. #{notable ? "Intègre #{diffusion} en dernière phrase." : ""}
        #{meteo.present? ? meteo : ""}
        #{ban}
        #{no_data}

        EXEMPLE DE SORTIE (adapte aux vraies données) :
        "Leur 0-0 à l'aller, le 15 octobre, avait laissé les deux équipes sur leur faim. Cette fois, Lens (6e) a plus à prouver : trois victoires de suite, et l'Europe semble à portée. Nantes (14e) doit décrocher un succès en déplacement pour sortir de sa spirale — match sur DAZN."

        Match : #{home} vs #{away} | #{comp} | #{date_fr}
        #{ctx}
      P

    # ── 3 : Angle tactique/météo — 3 phrases, une très courte ──
    when 3
      if meteo.present?
        <<~P.strip
          Tu es rédacteur football. Rédige un avant-match en français. Exactement 3 phrases. Pas de titre.
          #{meteo}
          Structure : phrase 1 = impact terrain/météo sur le jeu (8-12 mots max). Phrase 2 = enjeu sportif. Phrase 3 = diffusion ou classement.
          #{ban}
          #{no_data}

          EXEMPLE DE SORTIE par temps de pluie (adapte aux vraies données) :
          "Le terrain de Bollaert sera lourd ce soir. Dans ces conditions, le jeu direct et les duels physiques prendront le dessus sur les combinaisons — avantage pour Lens, qui affiche 3 victoires sur ses 5 derniers matchs. Nantes (14e) devra s'adapter à cette pelouse difficile pour espérer un résultat sur DAZN."

          Match : #{home} vs #{away} | #{comp} | #{date_fr}
          #{ctx}
        P
      else
        <<~P.strip
          Tu es rédacteur football. Rédige un avant-match en français. Exactement 3 phrases. Pas de titre.
          Angle tactique : quelle équipe est avantagée par le contexte (domicile, classement, forme) ?
          Ne commence ni par '#{home}' ni par '#{away}'. #{notable ? "Inclus #{diffusion}." : ""}
          Contrainte : une phrase interrogative ou affirmative forte, deux phrases d'analyse.
          #{ban}
          #{no_data}

          EXEMPLE DE SORTIE (adapte aux vraies données) :
          "Qui repart avec les trois points ce soir ? Lens (6e, 3V sur 5) part favori à domicile, mais Nantes reste une équipe difficile à battre quand elle joue bas et compact. Les fans trancheront sur DAZN à 21h."

          Match : #{home} vs #{away} | #{comp} | #{date_fr}
          #{ctx}
        P
      end

    # ── 4 : Angle domicile/extérieur — 3-4 phrases ──
    when 4
      <<~P.strip
        Tu es rédacteur football. Rédige un avant-match en français. 3 à 4 phrases. Pas de liste.
        Mets en avant l'avantage de jouer à domicile ou le défi de l'extérieur comme facteur clé.
        Appuie-toi sur la forme récente si disponible. #{notable ? "Inclus #{diffusion}." : ""}
        #{meteo.present? ? meteo : ""}
        #{ban}
        #{no_data}

        EXEMPLE DE SORTIE (adapte aux vraies données) :
        "Jouer à Bollaert reste un avantage réel pour Lens, invaincu à domicile sur ses 4 derniers matchs. Nantes, qui n'a pris qu'un point sur ses 5 derniers déplacements, aborde cette rencontre en position délicate. Lens (6e) table sur cet élan pour verrouiller la 6e place. Sur DAZN à 21h."

        Match : #{home} (domicile) vs #{away} (extérieur) | #{comp} | #{date_fr}
        #{ctx}
      P

    # ── 5 : Angle chiffres — exactement 2 phrases denses ──
    when 5
      <<~P.strip
        Tu es rédacteur football. Rédige un avant-match en français. Exactement 2 phrases. Pas de titre.
        Règle absolue : chaque phrase doit contenir au moins 2 chiffres précis (classement, forme, écart de points, score H2H).
        Style télégraphique, dense. #{notable ? "Mentionne #{diffusion}." : ""}
        #{meteo.present? ? meteo : ""}
        #{ban}
        #{no_data}

        EXEMPLE DE SORTIE (adapte aux vraies données) :
        "Lens (6e, 51 pts) reçoit Nantes (14e, 34 pts) : 17 points d'écart au classement, après un 0-0 au match aller. Bilan des 5 derniers matchs : 3V 1N 1D pour Lens contre 0V 2N 3D pour Nantes — les Sang et Or s'avancent sur DAZN avec un avantage clair."

        Match : #{home} vs #{away} | #{comp} | #{date_fr}
        #{ctx}
      P

    # ── 6 : Style radio — exactement 2 phrases sèches ──
    when 6
      <<~P.strip
        Tu es speaker radio. Rédige un flash avant-match en français. Exactement 2 phrases. Pas de titre.
        Phrase 1 : l'enjeu en 8 à 14 mots maximum. Phrase 2 : diffusion + un élément de contexte chiffré.
        Ne commence ni par '#{home}' ni par '#{away}'.
        #{meteo.present? ? "En fin de phrase 2, glisse l'impact terrain en 5 mots max : #{meteo}" : ""}
        #{ban}
        #{no_data}

        EXEMPLE DE SORTIE (adapte aux vraies données) :
        "Lens-Nantes, 6e contre 14e, pour l'Europe ou le maintien. Sur DAZN à 21h, avec un terrain rendu glissant par la pluie qui favorise le jeu direct des Sang et Or."

        Match : #{home} vs #{away} | #{comp} | #{date_fr}
        Diffusion : #{diffusion}
        #{ctx}
      P

    # ── 7 : Angle saison — 4 phrases, alternance courte/longue ──
    when 7
      <<~P.strip
        Tu es rédacteur football. Rédige un avant-match en français. Exactement 4 phrases. Pas de titre.
        Explique ce que ce match représente dans la saison de chaque équipe (titre, Europe, maintien, prestige).
        Contrainte de structure : phrases 1 et 3 courtes (6-14 mots), phrases 2 et 4 longues (20-32 mots).
        #{notable ? "Mentionne #{diffusion}." : ""}
        #{meteo.present? ? meteo : ""}
        #{ban}
        #{no_data}

        EXEMPLE DE SORTIE (adapte aux vraies données) :
        "La course à l'Europe s'accélère. Lens (6e) accueille Nantes (14e) avec l'ambition de s'accrocher à une place qualificative, après trois victoires consécutives qui ont relancé leur saison en seconde partie de championnat. Nantes cherche mieux. Les Canaris, à 12 points de toute ambition européenne, veulent au moins confirmer leur maintien avant la trêve — sur DAZN à 21h."

        Match : #{home} vs #{away} | #{comp} | #{date_fr}
        #{ctx}
      P

    # ── 8 : Angle surprise — quelle équipe peut faire l'upset ? ──
    when 8
      <<~P.strip
        Tu es rédacteur football. Rédige un avant-match en français. Exactement 3 phrases. Pas de titre.
        Commence par identifier l'équipe favorite, puis celle susceptible de créer la surprise.
        Appuie-toi sur la forme récente. #{notable ? "Intègre #{diffusion}." : ""}
        #{meteo.present? ? meteo : ""}
        #{ban}
        #{no_data}

        EXEMPLE DE SORTIE (adapte aux vraies données) :
        "Lens (6e) part favori à domicile avec 3 victoires sur les 5 derniers matchs. Pourtant, Nantes a arraché un 0-0 à l'aller et reste difficile à manoeuvrer quand il défend bas et repart en contre. L'upset est possible — et ça se passe sur DAZN."

        Match : #{home} vs #{away} | #{comp} | #{date_fr}
        #{ctx}
      P

    # ── 9 : Angle contexte large — ne commence pas par un nom d'équipe ──
    when 9
      <<~P.strip
        Tu es rédacteur football. Rédige un avant-match en français. Exactement 3 phrases. Pas de titre.
        Règle : la première phrase ne doit pas commencer par '#{home}', '#{away}', 'Ce soir', ni 'Le match'.
        Ouvre sur le contexte de la #{comp} cette saison, puis l'enjeu précis de cette affiche.
        #{notable ? "Intègre #{diffusion} en dernière phrase." : ""}
        #{meteo.present? ? meteo : ""}
        #{ban}
        #{no_data}

        EXEMPLE DE SORTIE (adapte aux vraies données) :
        "La Ligue 1 entre dans sa dernière ligne droite, et chaque point compte double. À Bollaert, Lens (6e) et Nantes (14e) jouent des enjeux opposés ce vendredi : les Sang et Or visent l'Europe, les Canaris consolident leur maintien. Sur DAZN à 21h."

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
    round     = match.round.to_s

    winner_text = if match.home_score > match.away_score
      "#{match.home_team} s'impose #{score}"
    elsif match.away_score > match.home_score
      "#{match.away_team} s'impose #{match.away_score}-#{match.home_score}"
    else
      "Match nul #{score}"
    end

    tmpl = match.id % 8
    summary_template(tmpl, match.home_team, match.away_team, match.competition,
                     date_fr, score, diffusion, winner_text, big_win, draw, gap, notable, round)
  end

  # Instruction ajoutée quand le match est à élimination directe (pas de poules)
  def self.knockout_instruction(round, home, away, winner_text, draw)
    return "" if round.blank? || round.match?(/group/i)

    round_fr = case round
    when /Round of 32/i then "seizième de finale"
    when /Round of 16/i then "huitième de finale"
    when /Quarter/i then "quart de finale"
    when /Semi/i then "demi-finale"
    when /Final/i then "finale"
    else round
    end

    loser = if !draw
      winner_text.include?(home) ? away : home
    end

    instruction = "IMPORTANT : ce match est un #{round_fr} (match à élimination directe). "
    if loser
      instruction += "#{loser} est éliminé(e) de la compétition. Ne parle JAMAIS de classement, de groupe, de points ou de qualification — le perdant rentre chez lui."
    else
      instruction += "Match nul dans le temps réglementaire (prolongations/tirs au but). Ne parle JAMAIS de classement, de groupe ou de points."
    end
    instruction
  end

  def self.summary_template(tmpl, home, away, comp, date_fr, score, diffusion, winner_text, big_win, draw, gap, notable, round = "")
    ban = banned_line
    ko = knockout_instruction(round, home, away, winner_text, draw)

    case tmpl

    # ── 0 : Dépêche AFP — 2 phrases, commence par le résultat ──
    when 0
      <<~P.strip
        Tu es rédacteur football. Résume ce match en 2 phrases. Style dépêche AFP. Pas de titre.
        Phrase 1 = score et vainqueur (max 14 mots). Phrase 2 = conséquence au classement ou en compétition.
        #{notable ? "Mentionne #{diffusion} si c'est une grande affiche." : ""}
        Aucune exagération, aucune invention.
        #{ko}
        #{ban}

        EXEMPLE DE SORTIE (adapte aux vraies données, ne copie pas Lens/Nantes) :
        "Lens s'impose 2-0 face à Nantes et remonte à la 5e place de Ligue 1. Cette victoire repousse les Canaris à 6 points de la zone de maintien — vu sur DAZN."

        Match : #{home} #{score} #{away} | #{comp} | #{round.presence || 'Journée'} | #{date_fr}
        Résultat : #{winner_text}
      P

    # ── 1 : Angle tournant — ne commence pas par le score, longueur variée ──
    when 1
      context = big_win ? "Victoire nette (#{gap} buts) : domination logique ou coup de théâtre ?" :
                draw     ? "Match nul : qui s'en sort mieux selon le classement ?" :
                           "Victoire d'un but : résultat serré, explique l'enjeu."
      <<~P.strip
        Tu es rédacteur football. Résume ce match en 2 à 3 phrases. Pas de titre. #{context}
        Ne commence pas par le score brut. Commence par le contexte ou ce que le résultat révèle.
        Contrainte : une phrase courte (6-12 mots) et une phrase longue (22-30 mots).
        #{notable ? "Intègre #{diffusion}." : ""}
        #{ko}
        #{ban}

        EXEMPLE DE SORTIE (adapte aux vraies données) :
        "Nantes ne gagne plus. Lens a profité de la fragilité défensive des Canaris pour s'imposer 2-0, consolidant ainsi sa place dans le top 6 à trois journées de la fin. Vu sur DAZN."

        Match : #{home} #{score} #{away} | #{comp} | #{round.presence || 'Journée'} | #{date_fr}
        Résultat : #{winner_text}
      P

    # ── 2 : 2 phrases sèches — conséquences d'abord ──
    when 2
      <<~P.strip
        Tu es rédacteur football. Résume ce match en exactement 2 phrases. Pas de titre.
        Phrase 1 = ce que ce résultat change dans la #{comp} (max 16 mots). Phrase 2 = score et détail marquant.
        Ne commence pas par 'Ce match'.
        #{ko}
        #{ban}

        EXEMPLE DE SORTIE (adapte aux vraies données) :
        "Lens s'accroche à la 6e place de Ligue 1 avec cette victoire. Les Sang et Or ont dominé Nantes 2-0 dans un match maîtrisé — diffusé sur DAZN."

        Match : #{home} #{score} #{away} | #{comp} | #{round.presence || 'Journée'} | #{date_fr}
        Résultat : #{winner_text}
      P

    # ── 3 : Conséquence d'abord, score ensuite ──
    when 3
      <<~P.strip
        Tu es rédacteur football. Résume ce match en 2 à 3 phrases. Pas de titre.
        Commence par ce que ce résultat change dans la #{comp}. Donne le score seulement en 2e ou 3e phrase.
        #{notable ? "Mentionne #{diffusion}." : ""} Aucun superlatif.
        #{ko}
        #{ban}

        EXEMPLE DE SORTIE (adapte aux vraies données) :
        "Lens consolide sa 6e place et garde une longueur d'avance sur ses concurrents pour l'Europe. Les Sang et Or ont écrasé Nantes 2-0 sur DAZN, avec une domination totale dès la première mi-temps."

        Match : #{home} #{score} #{away} | #{comp} | #{round.presence || 'Journée'} | #{date_fr}
        Résultat : #{winner_text}
      P

    # ── 4 : Angle perdant ou match nul — 2 phrases ──
    when 4
      loser_angle = draw ? "Analyse qui s'en sort le mieux selon le contexte au classement." :
                           "Que retient l'équipe battue ?"
      <<~P.strip
        Tu es rédacteur football. Résume ce match en 2 phrases. Pas de titre. #{loser_angle}
        Factuel. Ne commence pas par 'Malgré'.
        #{ko}
        #{ban}

        EXEMPLE DE SORTIE (adapte aux vraies données) :
        "Nantes repart de Bollaert avec rien, battu 2-0 dans une soirée difficile pour les Canaris. Ce résultat laisse Nantes à 6 points du bas de tableau, sans victoire en déplacement depuis 8 matchs."

        Match : #{home} #{score} #{away} | #{comp} | #{round.presence || 'Journée'} | #{date_fr}
        Résultat : #{winner_text}
      P

    # ── 5 : Style radio — 2 phrases orales ──
    when 5
      <<~P.strip
        Tu es speaker radio. Résume ce match en exactement 2 phrases. Pas de titre.
        Phrase 1 = ce qui s'est passé (8-13 mots). Phrase 2 = pourquoi c'est important.
        Ne commence pas par '#{home}' ni '#{away}'.
        #{ko}
        #{ban}

        EXEMPLE DE SORTIE (adapte aux vraies données) :
        "Victoire 2-0 de Lens sur Nantes ce vendredi. Les Sang et Or restent dans la course à l'Europe, à un point du top 5 — résultat à retrouver sur DAZN."

        Match : #{home} #{score} #{away} | #{comp} | #{round.presence || 'Journée'} | #{date_fr}
        Résultat : #{winner_text}
      P

    # ── 6 : Chiffres en avant ──
    when 6
      <<~P.strip
        Tu es rédacteur football. Résume ce match en 2 à 3 phrases. Pas de titre.
        Intègre obligatoirement au moins 2 chiffres au-delà du score (classement, écart de points, série).
        #{big_win ? "Insiste sur l'ampleur : #{gap} buts d'écart." : ""}
        #{notable ? "Mentionne #{diffusion}." : ""}
        #{ko}
        #{ban}

        EXEMPLE DE SORTIE (adapte aux vraies données) :
        "Lens s'impose 2-0 et remonte à la 6e place, à 4 points de l'Europe directe. Nantes reste 14e avec seulement 2 victoires sur ses 10 derniers matchs — vu sur DAZN."

        Match : #{home} #{score} #{away} | #{comp} | #{round.presence || 'Journée'} | #{date_fr}
        Résultat : #{winner_text}
      P

    # ── 7 : 3 phrases structurées (contexte → score → suite), chacune 8-18 mots ──
    when 7
      <<~P.strip
        Tu es rédacteur football. Résume ce match en exactement 3 phrases. Pas de titre.
        Structure : phrase 1 = contexte de la #{comp}, phrase 2 = résultat brut, phrase 3 = implication pour la suite.
        Chaque phrase entre 8 et 18 mots.
        #{notable ? "Glisse #{diffusion} dans l'une des phrases." : ""}
        #{ko}
        #{ban}

        EXEMPLE DE SORTIE (adapte aux vraies données) :
        "La lutte pour l'Europe en Ligue 1 reste ouverte. Lens s'impose 2-0 face à Nantes dans un match maîtrisé à Bollaert. Les Sang et Or s'installent 6e — le duel pour le dernier billet européen continue."

        Match : #{home} #{score} #{away} | #{comp} | #{round.presence || 'Journée'} | #{date_fr}
        Résultat : #{winner_text}
      P

    end
  end
end
