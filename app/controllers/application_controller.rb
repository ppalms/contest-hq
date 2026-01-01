class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_request_details
  before_action :authenticate
  before_action :set_selected_account

  around_action :set_time_zone, if: :current_user

  helper_method :current_user
  helper_method :require_role
  helper_method :breadcrumbs

  private

  def authenticate
    User.unscoped_by_account do
      if session_record = Session.find_by_id(cookies.signed[:session_token])
        Current.session = session_record
      else
        redirect_to landing_path
      end
    end
  end

  def set_selected_account
    if current_user&.sys_admin? && session[:selected_account_id]
      Current.selected_account = Account.find_by(id: session[:selected_account_id])
    end
  end

  def set_current_request_details
    Current.user_agent = request.user_agent
    Current.ip_address = request.ip
  end

  def current_user
    Current.user
  end

  def require_role(*role_names)
    unless role_names.any? { |role_name| current_user&.roles&.exists?(name: role_name) }
      redirect_to root_path
    end
  end

  def set_time_zone(&block)
    Time.use_zone(current_user&.time_zone, &block)
  end

  def breadcrumbs
    @breadcrumbs ||= []
  end

  def add_breadcrumb(name, path = nil)
    breadcrumbs << Breadcrumb.new(name, path)
  end
end
