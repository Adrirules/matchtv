namespace :share do
  desc "Envoie le rapport hebdomadaire de partages par email"
  task weekly_report: :environment do
    puts "📧 Envoi du rapport de partages..."
    ShareReportMailer.weekly_report.deliver_now
    puts "✅ Rapport envoyé à #{ShareReportMailer::REPORT_TO}"
  rescue => e
    puts "❌ Erreur lors de l'envoi : #{e.message}"
    raise
  end
end
