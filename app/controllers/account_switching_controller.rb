class AccountSwitchingController < ApplicationController
  before_action :require_sysadmin

  def switch
    if params[:account_id].present?
      account = Account.find(params[:account_id])
      session[:selected_account_id] = account.id
      Current.selected_account = account
      redirect_back(fallback_location: root_path, notice: "Switched to #{account.name}")
    else
      session.delete(:selected_account_id)
      Current.selected_account = nil
      redirect_back(fallback_location: root_path, notice: "Switched to all accounts view")
    end
  end

  def clear
    session.delete(:selected_account_id)
    Current.selected_account = nil
    redirect_to root_path, notice: "Switched to all accounts view"
  end

  private

  def require_sysadmin
    redirect_to root_path unless current_user&.sysadmin?
  end
end
