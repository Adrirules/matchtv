namespace :seo do

  # ---------------------------------------------------------------
  # seo:fetch_data PERIOD=weekly|monthly
  # Utilisé par la Routine Claude — sort les données GSC en JSON
  # ---------------------------------------------------------------
  desc "Fetch données GSC et sort en JSON (pour la Routine Claude)"
  task fetch_data: :environment do
    period = ENV.fetch("PERIOD", "weekly")
    gsc    = GscService.new

    if period == "monthly"
      current_start  = Date.today.prev_month.beginning_of_month
      current_end    = Date.today.prev_month.end_of_month
      previous_start = (current_start - 1).beginning_of_month
      previous_end   = current_start - 1
      label = begin
        months_fr = %w[janvier février mars avril mai juin juillet août septembre octobre novembre décembre]
        "#{months_fr[current_start.month - 1]} #{current_start.year}"
      end
    else
      wday           = Date.today.wday == 0 ? 7 : Date.today.wday
      current_start  = Date.today - wday + 1 - 7
      current_end    = current_start + 6
      previous_start = current_start - 7
      previous_end   = current_start - 1
      label          = "#{current_start.strftime('%d/%m')} au #{current_end.strftime('%d/%m/%Y')}"
    end

    # Période N-52 (même fenêtre l'an dernier — saisonnalité)
    year_ago_start = current_start - 365
    year_ago_end   = current_end   - 365

    current          = gsc.top_pages(start_date: current_start,  end_date: current_end,   limit: 50)
    previous         = gsc.top_pages(start_date: previous_start, end_date: previous_end,  limit: 50)
    year_ago         = gsc.top_pages(start_date: year_ago_start, end_date: year_ago_end,  limit: 50)
    summary_current  = gsc.summary(start_date: current_start,  end_date: current_end)
    summary_previous = gsc.summary(start_date: previous_start, end_date: previous_end)
    summary_year_ago = gsc.summary(start_date: year_ago_start,  end_date: year_ago_end)

    # Requêtes top 200 (impressions > 50 OU clics > 0)
    top_queries      = gsc.top_queries(start_date: current_start, end_date: current_end, limit: 200)

    # Requêtes x pages (cannibalisation)
    queries_by_page  = gsc.queries_by_page(start_date: current_start, end_date: current_end, limit: 200)

    # Cannibalisation : plusieurs pages sur la même requête
    cannibalization = queries_by_page
      .group_by { |r| r[:query] }
      .select   { |_, rows| rows.size > 1 && rows.sum { |r| r[:impressions] } > 50 }
      .map do |q, rows|
        { query: q, pages: rows.map { |r| { page: r[:page], type: r[:type], impressions: r[:impressions], position: r[:position] } } }
      end
      .sort_by  { |r| -r[:pages].sum { |p| p[:impressions] } }
      .first(20)

    # Delta WoW et N-52 par page
    prev_map     = previous.index_by { |r| r[:page] }
    year_ago_map = year_ago.index_by  { |r| r[:page] }
    pages_with_delta = current.map do |r|
      prev = prev_map[r[:page]]
      ya   = year_ago_map[r[:page]]
      r.merge(
        prev_position:    prev&.dig(:position),
        delta_pos_wow:    prev ? (r[:position] - prev[:position]).round(1) : nil,
        delta_pos_yoy:    ya   ? (r[:position] - ya[:position]).round(1)   : nil,
        impressions_yoy:  ya&.dig(:impressions),
        is_new:           prev.nil?
      )
    end

    # Segmentation par type de page
    by_type = pages_with_delta.group_by { |r| r[:type] }.transform_values do |pages|
      {
        count:       pages.size,
        impressions: pages.sum { |p| p[:impressions] },
        clicks:      pages.sum { |p| p[:clicks] },
        avg_ctr:     pages.any? ? (pages.sum { |p| p[:ctr] } / pages.size).round(1) : 0,
        avg_pos:     pages.any? ? (pages.sum { |p| p[:position] } / pages.size).round(1) : 0
      }
    end

    # Contexte football depuis la DB
    today = Date.today
    active_competitions  = Match.where(start_time: today..(today + 30)).distinct.pluck(:competition).compact.uniq.first(12)
    ending_soon          = Match.where(start_time: today..(today + 14)).distinct.pluck(:competition).compact.uniq.first(8)
    recent_competitions  = Match.where(start_time: (today - 14)..today).distinct.pluck(:competition).compact.uniq.first(10)
    next_big_matches     = Match.where(start_time: today..(today + 7))
                                .where("competition IN (?)", %w[Champions\ League Ligue\ 1 Premier\ League La\ Liga Bundesliga Serie\ A])
                                .order(:start_time).limit(10)
                                .pluck(:home_team, :away_team, :competition, :start_time)
                                .map { |h, a, c, t| "#{h} vs #{a} (#{c}) le #{t.strftime('%d/%m')}" }

    # Pages existantes (anti-hallucination maillage interne)
    existing_pages = {
      competitions: FootballApiService::COMPETITIONS_META.map { |c| c[:name] },
      blog_articles: Dir[Rails.root.join("app/content/blog/*.md")].map { |f| File.basename(f, ".md") }.sort,
      chaines: %w[canal-plus bein-sports dazn amazon-prime-video rmc-sport france-tv tf1 m6],
      top_teams: Match.where(start_time: (today - 90)..)
                      .flat_map { |m| [m.home_team, m.away_team] }
                      .compact.tally.sort_by { |_, n| -n }.first(30).map(&:first)
    }

    # Agenda droits TV (dates clés hardcodées + saisonnalité)
    tv_rights_calendar = [
      { event: "Reprise Ligue 1 2026-2027",          date: "2026-08-15", canal: "DAZN + beIN Sports",    note: "Fort pic de recherche 3 semaines avant" },
      { event: "Champions League phase de groupes",   date: "2026-09-15", canal: "Canal+",                note: "Pics sur pages LDC + équipes européennes" },
      { event: "Coupe du Monde 2026 — phase groupes", date: "2026-06-11", canal: "TF1 + beIN + Canal+",   note: "Compétition majeure en cours — forte saisonnalité" },
      { event: "Coupe du Monde 2026 — finale",        date: "2026-07-19", canal: "TF1",                   note: "Pic maximal — anticiper contenu résumés/stats" },
      { event: "Euro Espoirs 2025",                   date: "2025-06-11", canal: "L'Equipe / France TV",  note: "Audience modérée mais public jeune" },
    ].select { |e| Date.parse(e[:date]) >= today - 7 rescue false }

    output = {
      period:       period,
      label:        label,
      generated_at: today.strftime("%d/%m/%Y"),
      summary: {
        current:   summary_current,
        previous:  summary_previous,
        year_ago:  summary_year_ago
      },
      pages:             pages_with_delta,
      by_type:           by_type,
      top_queries:       top_queries,
      cannibalization:   cannibalization,
      football_context: {
        today:                today.strftime("%d/%m/%Y"),
        active_competitions:  active_competitions,
        ending_soon:          ending_soon,
        recent_competitions:  recent_competitions,
        next_big_matches:     next_big_matches,
        tv_rights_calendar:   tv_rights_calendar
      },
      existing_pages: existing_pages
    }

    puts JSON.pretty_generate(output)
  end

  # ---------------------------------------------------------------
  # seo:send_weekly  — appelé par la Routine avec CLAUDE_ANALYSIS
  # seo:send_monthly — idem
  # ---------------------------------------------------------------
  desc "Envoie le rapport SEO hebdo (CLAUDE_ANALYSIS=... optionnel)"
  task send_weekly: :environment do
    gsc = GscService.new

    wday          = Date.today.wday == 0 ? 7 : Date.today.wday
    current_start = Date.today - wday + 1 - 7
    current_end   = current_start + 6
    prev_start    = current_start - 7
    prev_end      = current_start - 1

    current  = gsc.top_pages(start_date: current_start, end_date: current_end,  limit: 25)
    previous = gsc.top_pages(start_date: prev_start,    end_date: prev_end,     limit: 25)
    summary_current  = gsc.summary(start_date: current_start, end_date: current_end)
    summary_previous = gsc.summary(start_date: prev_start,    end_date: prev_end)

    analysis   = ENV["CLAUDE_ANALYSIS"].presence || fallback_analysis(:weekly, current, previous, summary_current, summary_previous)
    week_label = "#{current_start.strftime('%d/%m')} au #{current_end.strftime('%d/%m/%Y')}"

    SeoReportMailer.weekly_report(
      current:          current,
      previous:         previous,
      summary_current:  summary_current,
      summary_previous: summary_previous,
      analysis:         analysis,
      week_label:       week_label
    ).deliver_now
    puts "✅ Rapport hebdo envoyé"
  rescue => e
    puts "❌ Erreur: #{e.message}"
    raise
  end

  desc "Envoie le rapport SEO mensuel (CLAUDE_ANALYSIS=... optionnel)"
  task send_monthly: :environment do
    gsc = GscService.new

    current_start  = Date.today.prev_month.beginning_of_month
    current_end    = Date.today.prev_month.end_of_month
    prev_start     = (current_start - 1).beginning_of_month
    prev_end       = current_start - 1

    current  = gsc.top_pages(start_date: current_start, end_date: current_end, limit: 30)
    previous = gsc.top_pages(start_date: prev_start,    end_date: prev_end,    limit: 30)
    summary_current  = gsc.summary(start_date: current_start, end_date: current_end)
    summary_previous = gsc.summary(start_date: prev_start,    end_date: prev_end)

    months_fr  = %w[janvier février mars avril mai juin juillet août septembre octobre novembre décembre]
    month_label = "#{months_fr[current_start.month - 1]} #{current_start.year}"
    analysis   = ENV["CLAUDE_ANALYSIS"].presence || fallback_analysis(:monthly, current, previous, summary_current, summary_previous)

    SeoReportMailer.monthly_report(
      current:          current,
      previous:         previous,
      summary_current:  summary_current,
      summary_previous: summary_previous,
      analysis:         analysis,
      month_label:      month_label
    ).deliver_now
    puts "✅ Rapport mensuel envoyé"
  rescue => e
    puts "❌ Erreur: #{e.message}"
    raise
  end

  # ---------------------------------------------------------------
  # Fallback Groq si la Routine n'a pas fourni d'analyse
  # ---------------------------------------------------------------
  def fallback_analysis(type, current, previous, summary, summary_prev)
    api_key = ENV["GROQ_API_KEY"]
    return "Analyse indisponible" unless api_key

    prev_map  = previous.index_by { |r| r[:page] }
    top_lines = current.first(15).map do |r|
      prev  = prev_map[r[:page]]
      delta = prev ? sprintf("%+.0f", r[:position] - prev[:position]) : "NEW"
      "#{r[:page]} | #{r[:impressions]} imp | #{r[:clicks]} clics | CTR #{r[:ctr]}% | pos #{r[:position]} (#{delta})"
    end.join("\n")

    active = Match.where(start_time: Date.today..(Date.today + 30)).distinct.pluck(:competition).compact.uniq.first(8)

    wow_c = summary_prev[:clicks] > 0 ? sprintf("%+.0f%%", ((summary[:clicks].to_f / summary_prev[:clicks]) - 1) * 100) : "N/A"
    wow_i = summary_prev[:impressions] > 0 ? sprintf("%+.0f%%", ((summary[:impressions].to_f / summary_prev[:impressions]) - 1) * 100) : "N/A"

    prompt = <<~PROMPT
      Tu es consultant SEO pour coupdenvoi.tv, site football français (programme TV, résultats, stats).

      MÉTRIQUES : Clics #{summary[:clicks]} (#{wow_c}), Impressions #{summary[:impressions]} (#{wow_i}), CTR #{summary[:ctr]}%, Pos #{summary[:position]}

      TOP PAGES :
      #{top_lines}

      CONTEXTE FOOT (#{Date.today.strftime('%d/%m/%Y')}) : #{active.join(', ').presence || 'inter-saison'}

      Génère en français : 1. CONTEXTE (pourquoi ces chiffres) 2. TOP 3 OPPORTUNITÉS 3. TOP 3 À DÉFENDRE 4. IDÉES CONTENU. Max 300 mots.
    PROMPT

    conn = Faraday.new do |f|
      f.request :json
      f.response :json
    end
    resp = conn.post("https://api.groq.com/openai/v1/chat/completions") do |req|
      req.headers["Authorization"] = "Bearer #{api_key}"
      req.headers["Content-Type"]  = "application/json"
      req.body = { model: "llama-3.3-70b-versatile", messages: [{ role: "user", content: prompt }], max_tokens: 600, temperature: 0.4 }.to_json
    end
    resp.body.dig("choices", 0, "message", "content") || "Analyse indisponible"
  rescue => e
    "Analyse indisponible (#{e.message})"
  end
end
