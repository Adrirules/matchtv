namespace :seo do
  desc "Fetch Google Search Console data for the weekly SEO report (outputs JSON)"
  task fetch_data: :environment do
    period = ENV.fetch('PERIOD', 'weekly')
    puts "🔍 Récupération des données GSC (#{period})..."

    service = GoogleSearchConsoleService.new
    data    = service.fetch_weekly_data

    puts "✅ Données récupérées"
    puts JSON.pretty_generate(data)
  rescue KeyError => e
    puts "❌ Variable d'environnement manquante : #{e.message}"
    puts "   → Définir GOOGLE_SERVICE_ACCOUNT_JSON et, si besoin, GSC_SITE_URL"
    raise
  rescue => e
    puts "❌ Erreur : #{e.class} — #{e.message}"
    raise
  end

  desc "Envoie le rapport SEO hebdomadaire par email (CLAUDE_ANALYSIS=...)"
  task send_weekly: :environment do
    analysis = ENV.fetch('CLAUDE_ANALYSIS', '').strip

    if analysis.empty?
      puts "⚠️  CLAUDE_ANALYSIS est vide — le rapport sera envoyé sans analyse."
    end

    puts "📧 Envoi du rapport SEO..."
    SeoReportMailer.weekly_report(analysis).deliver_now
    puts "✅ Rapport envoyé à #{SeoReportMailer::REPORT_TO}"
  rescue => e
    puts "❌ Erreur lors de l'envoi : #{e.message}"
    raise
  end
end
