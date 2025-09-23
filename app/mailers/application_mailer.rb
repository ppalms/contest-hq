class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@contesthq.app"
  layout "mailer"
end
