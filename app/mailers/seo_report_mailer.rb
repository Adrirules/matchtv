class SeoReportMailer < ApplicationMailer
  REPORT_TO = "coupdenvoi.tv@gmail.com"

  def weekly_report(analysis)
    @analysis     = analysis
    @generated_at = Time.current.strftime("%d/%m/%Y à %Hh%M")
    @week_label   = "semaine du #{7.days.ago.strftime('%d/%m')}"

    mail(
      to:      REPORT_TO,
      subject: "Coup d'Envoi TV — Rapport SEO #{@week_label}"
    )
  end
end
