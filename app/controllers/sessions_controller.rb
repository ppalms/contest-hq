class SessionsController < ApplicationController
  skip_before_action :authenticate, only: %i[ new create ]

  before_action :set_session, only: :destroy

  def index
    @sessions = Current.user.sessions.order(created_at: :desc)
  end

  def new
  end

  def create
    User.unscoped_by_account do
      if user = User.authenticate_by(email: params[:email], password: params[:password])
        @session = user.sessions.create!
        cookies.signed.permanent[:session_token] = { value: @session.id, httponly: true }

        redirect_to root_path, notice: "Signed in successfully"
      else
        redirect_to sign_in_path(email_hint: params[:email]), alert: "Incorrect email or password"
      end
    end
  end

  def destroy
    @session.destroy; redirect_to(sessions_path, notice: "You have been signed out")
  end

  private
    def set_session
      @session = Current.user.sessions.find(params[:id])
    end
end
