namespace :seo do
  GROQ_URL   = "https://api.groq.com/openai/v1/chat/completions".freeze
  GROQ_MODEL = "llama-3.3-70b-versatile".freeze

  desc "Rapport SEO hebdomadaire (mercredi uniquement)"
  task weekly_report: :environment do
    unless Date.today.wednesday?
      puts "⏭️  Pas mercredi (#{Date.today.strftime('%A')}) — envoi ignoré"
      next
    end

    puts "📊 Récupération données GSC..."
    gsc = GscService.new

    # Semaine précédente : lundi→dimanche
    last_monday = Date.today - Date.today.wday + 1 - 7
    last_sunday = last_monday + 6
    prev_monday = last_monday - 7
    prev_sunday = last_monday - 1

    current  = gsc.top_pages(start_date: last_monday, end_date: last_sunday, limit: 25)
    previous = gsc.top_pages(start_date: prev_monday, end_date: prev_sunday, limit: 25)
    summary_current  = gsc.summary(start_date: last_monday, end_date: last_sunday)
    summary_previous = gsc.summary(start_date: prev_monday, end_date: prev_sunday)

    puts "🤖 Analyse Groq..."
    analysis = generate_analysis(:weekly, current, previous, summary_current, summary_previous)

    week_label = "#{last_monday.strftime('%d/%m')} au #{last_sunday.strftime('%d/%m/%Y')}"
    puts "📧 Envoi du rapport..."
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

  desc "Rapport SEO mensuel (4ème jour du mois uniquement)"
  task monthly_report: :environment do
    unless Date.today.day == 4
      puts "⏭️  Pas le 4 du mois (aujourd'hui : #{Date.today.day}) — envoi ignoré"
      next
    end

    puts "📊 Récupération données GSC (mois complet)..."
    gsc = GscService.new

    # Mois précédent complet
    last_month_end   = Date.today.prev_month.end_of_month
    last_month_start = Date.today.prev_month.beginning_of_month
    prev_month_end   = last_month_start - 1
    prev_month_start = prev_month_end.beginning_of_month

    current  = gsc.top_pages(start_date: last_month_start, end_date: last_month_end, limit: 30)
    previous = gsc.top_pages(start_date: prev_month_start, end_date: prev_month_end, limit: 30)
    summary_current  = gsc.summary(start_date: last_month_start, end_date: last_month_end)
    summary_previous = gsc.summary(start_date: prev_month_start, end_date: prev_month_end)

    puts "🤖 Analyse Groq..."
    analysis = generate_analysis(:monthly, current, previous, summary_current, summary_previous)

    months_fr = %w[janvier février mars avril mai juin juillet août septembre octobre novembre décembre]
    month_label = "#{months_fr[last_month_start.month - 1]} #{last_month_start.year}"

    puts "📧 Envoi du rapport mensuel..."
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

  private

  def generate_analysis(type, current, previous, summary, summary_prev)
    api_key = ENV["GROQ_API_KEY"]
    return "Analyse indisponible (GROQ_API_KEY manquant)" unless api_key

    # Contexte football depuis la DB
    active_competitions = Match.where(start_time: Date.today..(Date.today + 30))
                               .distinct.pluck(:competition).compact.uniq.first(10)
    recent_competitions = Match.where(start_time: (Date.today - 14)..Date.today)
                               .distinct.pluck(:competition).compact.uniq.first(10)

    # Top pages avec delta
    prev_map = previous.index_by { |r| r[:page] }
    top_lines = current.first(15).map do |r|
      prev = prev_map[r[:page]]
      delta = prev ? sprintf("%+.0f", r[:position] - prev[:position]) : "NEW"
      "#{r[:page]} | #{r[:impressions]} imp | #{r[:clicks]} clics | CTR #{r[:ctr]}% | pos #{r[:position]} (#{delta})"
    end.join("\n")

    wow_clicks = summary_prev[:clicks] > 0 ? sprintf("%+.0f%%", ((summary[:clicks].to_f / summary_prev[:clicks]) - 1) * 100) : "N/A"
    wow_impressions = summary_prev[:impressions] > 0 ? sprintf("%+.0f%%", ((summary[:impressions].to_f / summary_prev[:impressions]) - 1) * 100) : "N/A"

    period = type == :weekly ? "cette semaine" : "ce mois"

    prompt = <<~PROMPT
      Tu es consultant SEO pour coupdenvoi.tv, un site football français (programme TV, résultats, stats).
      Monétisation : Google AdSense. Objectif : maximiser les impressions organiques Google.

      MÉTRIQUES #{period.upcase} :
      Clics : #{summary[:clicks]} (#{wow_clicks} vs période précédente)
      Impressions : #{summary[:impressions]} (#{wow_impressions} vs période précédente)
      CTR moyen : #{summary[:ctr]}%
      Position moyenne : #{summary[:position]}

      TOP PAGES (impressions, clics, CTR, position, delta position) :
      #{top_lines}

      CONTEXTE FOOTBALL ACTUEL (#{Date.today.strftime('%d/%m/%Y')}) :
      Compétitions actives / à venir (30 jours) : #{active_competitions.join(', ').presence || 'aucune'}
      Compétitions récentes (14 derniers jours) : #{recent_competitions.join(', ').presence || 'aucune'}

      Génère un rapport SEO concis en français avec ces 4 sections :
      1. LECTURE DU CONTEXTE (2-3 phrases : pourquoi ces chiffres vu le calendrier foot)
      2. TOP 3 OPPORTUNITÉS (pages à fort potentiel avec action concrète)
      3. TOP 3 PAGES À DÉFENDRE (performers à maintenir)
      4. IDÉES CONTENU (1-2 articles à produire dans les 7 prochains jours)

      Sois direct, concis, pas de blabla. Maximum 300 mots.
    PROMPT

    begin
      conn = Faraday.new(url: GROQ_URL) do |f|
        f.request :json
        f.response :json
      end
      resp = conn.post do |req|
        req.headers["Authorization"] = "Bearer #{api_key}"
        req.headers["Content-Type"]  = "application/json"
        req.body = {
          model:       GROQ_MODEL,
          messages:    [{ role: "user", content: prompt }],
          max_tokens:  600,
          temperature: 0.4
        }.to_json
      end
      resp.body.dig("choices", 0, "message", "content") || "Analyse indisponible"
    rescue => e
      Rails.logger.error "[seo:report] Groq error: #{e.message}"
      "Analyse temporairement indisponible"
    end
  end
end
