class PublicController < ApplicationController
  skip_before_action :authenticate

  def landing
    # Landing page for unauthenticated users
    # Redirect to dashboard if already logged in
    redirect_to root_path if Current.session
  end
end
