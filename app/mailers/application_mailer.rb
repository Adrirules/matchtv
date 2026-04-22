class ApplicationMailer < ActionMailer::Base
  default from: "Coup d'Envoi TV <#{ENV.fetch('GMAIL_USER', 'coupdenvoi@gmail.com')}>"
  layout "mailer"
end
