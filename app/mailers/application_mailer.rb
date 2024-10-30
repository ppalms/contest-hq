class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@ppalmer.dev"
  layout "mailer"
end
