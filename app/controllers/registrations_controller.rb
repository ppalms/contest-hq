class RegistrationsController < ApplicationController
  skip_before_action :authenticate

  def new
    @user = User.new
    account = Account.find_by(name: "Contest HQ")
    @user.account = account
  end

  def create
    @user = User.new(user_params)

    if params[:role_ids].nil?
      @user.roles = [ Role.find_by(name: "Director") ]
    else
      @user.roles = Role.where(id: params[:role_ids])
    end

    if @user.save
      session_record = @user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: session_record.id, httponly: true }

      send_email_verification
      redirect_to root_path, notice: "Welcome! You have signed up successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def user_params
      params.expect(user: [ :first_name, :last_name, :email, :password, :password_confirmation, :time_zone, :account_id, role_ids: [] ])
    end

    def send_email_verification
      UserMailer.with(user: @user).email_verification.deliver_later
    end
end
