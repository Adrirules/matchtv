namespace :share do
  desc "Envoie le rapport hebdomadaire de partages (lundi uniquement)"
  task weekly_report: :environment do
    unless Date.today.monday?
      puts "⏭️  Pas lundi (#{Date.today.strftime('%A')}) — envoi ignoré"
      next
    end
    puts "📧 Envoi du rapport de partages..."
    ShareReportMailer.weekly_report.deliver_now
    puts "✅ Rapport envoyé à #{ShareReportMailer::REPORT_TO}"
  rescue => e
    puts "❌ Erreur lors de l'envoi : #{e.message}"
    raise
  end
end
