class BetaSignupMailer < ApplicationMailer
  def new_signup(signup_params)
    @organization = signup_params[:organization]
    @name = signup_params[:name]
    @email = signup_params[:email]
    @contests = signup_params[:contests]

    mail(
      to: "patrick@contesthq.app",
      subject: "New Beta Signup: #{@organization}",
      from: "no-reply@contesthq.app"
    )
  end
end
