namespace :gsc do
  desc "Vérifie les nouvelles 404 du jour — envoie un email si spike détecté"
  task check_errors: :environment do
    new_errors = CrawlError.new_today
    count      = new_errors.count

    puts "📊 [#{Time.now.strftime('%H:%M')}] Crawl errors — #{count} nouvelle(s) URL(s) en 404 aujourd'hui"

    if count == 0
      puts "  ✅ Aucune nouvelle 404 — tout va bien"
      next
    end

    # Toujours logger les nouvelles URLs dans les logs Heroku
    new_errors.order(count: :desc).limit(50).each do |e|
      puts "  ⚠️  #{e.url} (#{e.count} hit#{'s' if e.count > 1})"
    end

    # Email seulement si spike
    unless CrawlError.spike_today?
      puts "  ℹ️  Sous le seuil d'alerte (#{CrawlError::ALERT_THRESHOLD}) — pas d'email"
      next
    end

    # Marquer comme alerté pour ne pas renvoyer
    already_alerted = new_errors.where(alert_sent: true).exists?
    if already_alerted
      puts "  ℹ️  Alerte déjà envoyée aujourd'hui"
      next
    end

    # Construire le body de l'email
    top_urls = new_errors.order(count: :desc).limit(30).pluck(:url, :count)
    body = <<~BODY
      🚨 Alerte 404 — coupdenvoi.tv

      #{count} nouvelles URLs en 404 détectées aujourd'hui (seuil : #{CrawlError::ALERT_THRESHOLD}).

      Top URLs par nombre de hits :
      #{top_urls.map { |url, c| "  #{c}x #{url}" }.join("\n")}

      → Analyser et corriger : rails gsc:check_errors
      → Voir tout l'historique : CrawlError.order(first_seen: :desc).limit(100)
    BODY

    # Envoi via sendgrid/smtp configuré dans ActionMailer
    begin
      mail = Mail.new do
        from    'coupdenvoi.tv@gmail.com'
        to      'coupdenvoi.tv@gmail.com'
        subject "🚨 #{count} nouvelles 404 sur coupdenvoi.tv — action requise"
        body    body
      end
      mail.delivery_method :smtp, address: 'smtp.gmail.com',
                                   port: 587,
                                   user_name: ENV['GMAIL_USER'],
                                   password: ENV['GMAIL_APP_PASSWORD'],
                                   authentication: :plain,
                                   enable_starttls_auto: true
      mail.deliver!

      new_errors.update_all(alert_sent: true)
      puts "  ✅ Email d'alerte envoyé à coupdenvoi.tv@gmail.com"
    rescue => e
      puts "  ❌ Échec envoi email : #{e.message}"
      Rails.logger.error("[gsc:check_errors] Email failed: #{e.message}")
    end
  end

  desc "Affiche un résumé des 404 des 7 derniers jours"
  task summary: :environment do
    puts "\n📋 Résumé des 404 — 7 derniers jours"
    puts "=" * 50

    (0..6).each do |i|
      date  = Date.today - i.days
      count = CrawlError.where(first_seen: date).count
      label = i == 0 ? " (aujourd'hui)" : ""
      puts "  #{date.strftime('%d/%m')}#{label} : #{count} nouvelle(s) URL(s)"
    end

    puts "\nTop 20 URLs les plus frappées :"
    CrawlError.order(count: :desc).limit(20).each do |e|
      puts "  #{e.count.to_s.rjust(4)}x  #{e.url}  (depuis #{e.first_seen})"
    end

    puts "\nTotal en DB : #{CrawlError.count} URLs uniques en 404"
  end
end
