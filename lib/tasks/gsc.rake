namespace :gsc do
  # Patterns de scans bots/sécurité — jamais de vraies pages utilisateur
  BOT_PROBE_PATTERNS = [
    # Credentials & config
    /^\/\.env/i,
    /\/\.env/i,
    /^\/\.aws/i,
    /^\/config\.json/i,
    /^\/settings\.json/i,
    /^\/app-config\.json/i,
    /^\/runtime-config/i,
    /^\/asset-manifest\.json/i,
    /^\/env\.(js|json)$/i,
    /^\/__env/i,
    /sftp[^\/]*\.json/i,       # sftp-config.json, .vscode/sftp.json
    /^\/\.vscode\//i,
    # PHP — tout fichier .php sur un site Rails = scan bot
    /\.php$/i,
    /^\/cgi-bin\//i,
    # WordPress & CMS scans
    /^\/wp-/i,
    /^\/wp\.php/i,
    /^\/xmlrpc\.php/i,
    /^\/admin\.php/i,
    /^\/phpmyadmin/i,
    # Infrastructure & outils
    /^\/graphql/i,
    /^\/backend\//i,
    /^\/public\//i,
    /^\/api\/(v\d+\/)?(settings|config|env|v\d+\/env)/i,
    /^\/assets\/.*\.map$/i,
    /^\/\.git/i,
    /^\/\.htaccess/i,
    /^\/vendor\//i,
    /^\/autodiscover/i,
    /^\/\.well-known/i,        # ACME / security.txt — pas une page Rails
  ].freeze

  def bot_probe?(url)
    BOT_PROBE_PATTERNS.any? { |pattern| url.match?(pattern) }
  end

  # Suggestions de redirects automatiques basées sur les patterns connus
  def suggest_redirect(url)
    case url
    when /^\/ligue\/(.+)$/
      slug = $1
      target = "/competitions/#{slug}"
      { action: :redirect, from: url, to: target }
    when /^\/matchs\/(.+)$/
      { action: :redirect, from: url, to: "/matches/#{$1}" }
    when /^\/equipe\/(.+)$/
      { action: :redirect, from: url, to: "/equipes/#{$1}" }
    when /^\/joueur\/(.+)$/
      { action: :redirect, from: url, to: "/joueurs/#{$1}" }
    when /^\/classement\/(.+)$/
      { action: :redirect, from: url, to: "/classements/#{$1}" }
    else
      nil
    end
  end

  desc "Vérifie les nouvelles 404 — catégorise bots vs vraies erreurs, alerte si besoin"
  task check_errors: :environment do
    new_errors = CrawlError.new_today.order(count: :desc)
    all_count  = new_errors.count

    if all_count == 0
      puts "✅ [#{Time.now.strftime('%H:%M')}] Aucune nouvelle 404 aujourd'hui"
      next
    end

    # Catégorisation
    bot_probes  = new_errors.select { |e| bot_probe?(e.url) }
    real_errors = new_errors.reject { |e| bot_probe?(e.url) }

    puts "📊 [#{Time.now.strftime('%H:%M')}] #{all_count} nouvelles 404 — #{bot_probes.size} scans bots, #{real_errors.size} vraies 404"

    bot_probes.each  { |e| puts "  🤖 [BOT]  #{e.url}" }
    real_errors.each { |e| puts "  ⚠️  [404]  #{e.url} (#{e.count} hit#{'s' if e.count > 1})" }

    # Seuil basé uniquement sur les vraies erreurs
    real_count = real_errors.size

    # Email si spike de vraies 404 OU si c'est le premier run du jour (pour recap quotidien)
    should_alert = real_count >= CrawlError::ALERT_THRESHOLD ||
                   (all_count >= CrawlError::ALERT_THRESHOLD && bot_probes.any?)

    unless should_alert
      puts "  ℹ️  #{real_count} vraies 404 — sous le seuil (#{CrawlError::ALERT_THRESHOLD}), pas d'email"
      next
    end

    already_alerted = new_errors.where(alert_sent: true).exists?
    if already_alerted
      puts "  ℹ️  Alerte déjà envoyée aujourd'hui"
      next
    end

    # Analyse des vraies 404 — suggestions de redirects
    redirects_suggested = []
    needs_review        = []

    real_errors.each do |e|
      suggestion = suggest_redirect(e.url)
      if suggestion
        redirects_suggested << suggestion.merge(hits: e.count)
      else
        needs_review << { url: e.url, hits: e.count }
      end
    end

    # Construction de l'email
    lines = []
    lines << "Rapport 404 automatique — coupdenvoi.tv"
    lines << "=" * 50
    lines << ""
    lines << "#{all_count} nouvelles URLs en 404 aujourd'hui."
    lines << ""

    if bot_probes.any?
      lines << "🤖 #{bot_probes.size} scans de bots ignorés automatiquement"
      lines << "   (scans .env / config.json / .aws / WordPress / etc.)"
      lines << "   → Aucune action nécessaire, comportement normal."
      lines << ""
    end

    if real_errors.empty?
      lines << "✅ Aucune vraie 404 utilisateur détectée."
      lines << "   Toutes les URLs sont des scans automatiques de bots."
    else
      lines << "⚠️  #{real_errors.size} vraies 404 utilisateur :"
      lines << ""

      if redirects_suggested.any?
        lines << "✅ #{redirects_suggested.size} redirect(s) à appliquer (patterns connus) :"
        redirects_suggested.each do |r|
          lines << "   #{r[:hits]}x  #{r[:from]}  →  #{r[:to]}"
        end
        lines << ""
        lines << "   Commande routes.rb :"
        redirects_suggested.each do |r|
          lines << "   get '#{r[:from]}', to: redirect('#{r[:to]}')"
        end
        lines << ""
      end

      if needs_review.any?
        lines << "🔍 #{needs_review.size} URL(s) à analyser manuellement :"
        needs_review.each do |e|
          lines << "   #{e[:hits]}x  #{e[:url]}"
        end
        lines << ""
        lines << "   → Vérifier si URL interne cassée ou crawl d'une ancienne page indexée."
      end
    end

    lines << ""
    lines << "—"
    lines << "Généré le #{Time.now.strftime('%d/%m/%Y à %H:%M')}"
    lines << "Voir l'historique : heroku run rails gsc:summary -a coup-denvoi"

    body = lines.join("\n")

    real_subject = if real_errors.empty?
      "✅ #{all_count} scans bots ignorés — aucune vraie 404 | coupdenvoi.tv"
    elsif needs_review.any?
      "⚠️ #{real_errors.size} vraies 404 à vérifier (#{bot_probes.size} bots ignorés) | coupdenvoi.tv"
    else
      "ℹ️ #{all_count} 404 détectées — #{bot_probes.size} bots + #{redirects_suggested.size} redirects à appliquer | coupdenvoi.tv"
    end

    begin
      mail = Mail.new do
        from    'coupdenvoi.tv@gmail.com'
        to      'coupdenvoi.tv@gmail.com'
        subject real_subject
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
      puts "  ✅ Email envoyé : #{real_subject}"
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
      all   = CrawlError.where(first_seen: date)
      bots  = all.select { |e| bot_probe?(e.url) }.size
      real  = all.size - bots
      label = i == 0 ? " (aujourd'hui)" : ""
      puts "  #{date.strftime('%d/%m')}#{label} : #{all.size} total (#{bots} bots, #{real} vraies)"
    end

    puts "\nTop 20 URLs les plus frappées (vraies 404 uniquement) :"
    CrawlError.order(count: :desc).limit(50).each do |e|
      next if bot_probe?(e.url)
      puts "  #{e.count.to_s.rjust(4)}x  #{e.url}  (depuis #{e.first_seen})"
    end

    puts "\nTotal en DB : #{CrawlError.count} URLs uniques (#{CrawlError.all.select { |e| bot_probe?(e.url) }.size} bots)"
  end
end
