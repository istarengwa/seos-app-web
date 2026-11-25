class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("SEOS_MAIL_FROM", "SEOS <noreply@example.test>") }
  layout "mailer"
end
