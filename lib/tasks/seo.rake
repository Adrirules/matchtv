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

    current  = gsc.top_pages(start_date: current_start,  end_date: current_end,  limit: 25)
    previous = gsc.top_pages(start_date: previous_start, end_date: previous_end, limit: 25)
    summary_current  = gsc.summary(start_date: current_start,  end_date: current_end)
    summary_previous = gsc.summary(start_date: previous_start, end_date: previous_end)

    # Contexte football depuis la DB
    active_competitions = Match.where(start_time: Date.today..(Date.today + 30))
                               .distinct.pluck(:competition).compact.uniq.first(10)
    recent_competitions = Match.where(start_time: (Date.today - 14)..Date.today)
                               .distinct.pluck(:competition).compact.uniq.first(10)

    # Delta position page par page
    prev_map = previous.index_by { |r| r[:page] }
    pages_with_delta = current.map do |r|
      prev = prev_map[r[:page]]
      r.merge(
        prev_position: prev&.dig(:position),
        delta_pos:     prev ? (r[:position] - prev[:position]).round(1) : nil,
        is_new:        prev.nil?
      )
    end

    output = {
      period:         period,
      label:          label,
      generated_at:   Date.today.strftime("%d/%m/%Y"),
      summary: {
        current:  summary_current,
        previous: summary_previous
      },
      pages:          pages_with_delta,
      football_context: {
        active_competitions:  active_competitions,
        recent_competitions:  recent_competitions,
        today:                Date.today.strftime("%d/%m/%Y")
      }
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
