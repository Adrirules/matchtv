namespace :editorial do
  desc "Génère un plan éditorial blog via Groq et l'envoie par email"
  task plan: :environment do
    api_key = ENV["GROQ_API_KEY"]
    unless api_key
      puts "❌ GROQ_API_KEY manquant"
      next
    end

    puts "📅 Génération du plan éditorial..."

    today = Date.today

    # --- Contexte football (30 prochains jours) ---
    active_competitions = Match.where(start_time: today..(today + 30))
                               .distinct.pluck(:competition).compact.uniq

    big_events = Match.where(start_time: today..(today + 30))
                      .order(:start_time).limit(20)
                      .pluck(:home_team, :away_team, :competition, :start_time)
                      .map { |h, a, c, t| "#{h} vs #{a} (#{c}) le #{t.strftime('%d/%m')}" }

    # --- Articles blog existants (anti-cannibalisation) ---
    existing_slugs = Dir[Rails.root.join("app/content/blog/*.md")]
                       .map { |f| File.basename(f, ".md") }.sort

    # Prochain slot de publication libre (on publie 1 article/jour)
    last_date = Dir[Rails.root.join("app/content/blog/*.md")].map do |f|
      content = File.read(f)
      m = content.match(/^published_at:\s*(\d{4}-\d{2}-\d{2})/)
      Date.parse(m[1]) rescue nil
    end.compact.max || today
    next_slot = [last_date + 1, today].max

    # --- GSC : requêtes à fort volume sans article dédié ---
    gsc_gaps = begin
      gsc           = GscService.new
      start_date    = today - 28
      top_queries   = gsc.top_queries(start_date: start_date, end_date: today - 1, limit: 200)
      blog_words = existing_slugs.flat_map { |s| s.split("-") }.to_set
      top_queries
        .select { |q| q[:impressions].to_i > 80 }
        .reject { |q| blog_words.include?(q[:query].split.first.to_s.downcase) }
        .sort_by { |q| -q[:impressions].to_i }
        .first(20)
        .map { |q| "#{q[:query]} (#{q[:impressions]} imp, pos #{q[:position]})" }
    rescue => e
      Rails.logger.warn("[editorial:plan] GSC unavailable: #{e.message}")
      []
    end

    # --- Prompt Groq ---
    prompt = <<~PROMPT
      Tu es consultant éditorial pour coupdenvoi.tv, site football français (programme TV, résultats, stats).
      Stratégie blog : 70% guides pratiques (chaînes TV, abonnements, où voir quel championnat) — 30% éditorial passion.
      Monétisation : AdSense (en cours de validation) + affiliation DAZN active.

      ARTICLES BLOG DÉJÀ PUBLIÉS (ne pas cannibaliser) :
      #{existing_slugs.join(', ')}

      COMPÉTITIONS ACTIVES (30 prochains jours) :
      #{active_competitions.join(', ').presence || 'inter-saison'}

      MATCHS IMPORTANTS À VENIR :
      #{big_events.first(10).join("\n").presence || 'Aucun match majeur identifié'}

      REQUÊTES GSC SANS ARTICLE DÉDIÉ (opportunités SEO) :
      #{gsc_gaps.join("\n").presence || 'Données GSC indisponibles'}

      PROCHAIN SLOT DE PUBLICATION LIBRE : #{next_slot.strftime('%d/%m/%Y')}

      ---

      Génère exactement 5 idées d'articles. Pour chacune, utilise ce format :

      ## [numéro]. [TITRE H1 exact]
      - Slug : [slug-en-minuscules-sans-accents]
      - Mot-clé principal : [keyword] (~[X] imp/semaine estimé)
      - Intention : [informationnelle / transactionnelle / navigationnelle]
      - Structure : H2: [...] | H2: [...] | H2: [...] | FAQ
      - Longueur cible : [X mots]
      - Niveau éditorial : [Programmatique OK / Enrichi +200 mots humains / 100% humain 800+ mots]
      - Maillage vers : [/chaines/xxx] [/competitions/xxx] [/classements/xxx]
      - Pourquoi maintenant : [lien calendrier ou saisonnalité précis]
      - Date suggérée : [JJ/MM/YYYY — en partant du slot #{next_slot.strftime('%d/%m/%Y')}, 1 article/jour]

      Règles :
      - Prioriser les guides pratiques TV/abonnements (intent transactionnel = meilleur pour affiliation)
      - Ne jamais proposer un article qui cannibalise un slug existant
      - Proposer au moins 1 article lié au calendrier foot des 30 prochains jours
      - Varier les longueurs (1 court 600 mots, 2 moyens 900 mots, 2 longs 1200 mots)
      - Répondre en français, ton direct
    PROMPT

    # --- Appel Groq ---
    puts "  🤖 Appel Groq..."
    conn = Faraday.new do |f|
      f.request :json
      f.response :json
    end
    resp = conn.post("https://api.groq.com/openai/v1/chat/completions") do |req|
      req.headers["Authorization"] = "Bearer #{api_key}"
      req.headers["Content-Type"]  = "application/json"
      req.body = {
        model:       "llama-3.3-70b-versatile",
        messages:    [{ role: "user", content: prompt }],
        max_tokens:  2000,
        temperature: 0.6
      }.to_json
    end

    plan = resp.body.dig("choices", 0, "message", "content")
    unless plan.present?
      puts "❌ Groq n'a pas retourné de contenu"
      next
    end

    puts plan
    puts "\n📧 Envoi par email..."

    # --- Email ---
    body = <<~BODY
      📅 Plan éditorial coupdenvoi.tv — généré le #{today.strftime('%d/%m/%Y')}

      Prochain slot libre : #{next_slot.strftime('%d/%m/%Y')}
      Compétitions actives : #{active_competitions.first(6).join(', ')}

      ---

      #{plan}

      ---
      Généré via rails editorial:plan
    BODY

    mail = Mail.new do
      from    'coupdenvoi.tv@gmail.com'
      to      'coupdenvoi.tv@gmail.com'
      subject "📅 Plan éditorial blog — #{today.strftime('%d/%m/%Y')}"
      body    body
    end
    mail.delivery_method :smtp,
      address:              'smtp.gmail.com',
      port:                 587,
      user_name:            ENV['GMAIL_USER'],
      password:             ENV['GMAIL_APP_PASSWORD'],
      authentication:       :plain,
      enable_starttls_auto: true
    mail.deliver!

    puts "✅ Plan éditorial envoyé à coupdenvoi.tv@gmail.com"
  rescue => e
    puts "❌ Erreur : #{e.message}"
    Rails.logger.error("[editorial:plan] #{e.message}")
  end
end
