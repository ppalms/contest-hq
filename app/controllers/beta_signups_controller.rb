class BetaSignupsController < ApplicationController
  skip_before_action :authenticate

  def create
    beta_params = params.permit(:organization, :name, :email, :contests)

    BetaSignupMailer.new_signup(beta_params).deliver_now

    Rails.logger.info "Beta signup: #{beta_params}"

    redirect_to root_path, notice: "Thank you for your interest! We'll be in touch soon about beta access."
  rescue => e
    Rails.logger.error "Beta signup error: #{e.message}"
    redirect_to root_path, alert: "There was an error processing your request. Please try again or email us directly."
  end
end
