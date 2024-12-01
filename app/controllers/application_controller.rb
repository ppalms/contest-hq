class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_request_details
  before_action :authenticate

  around_action :set_time_zone, if: :current_user

  helper_method :current_user
  helper_method :require_role

  private
    def authenticate
      if session_record = Session.find_by_id(cookies.signed[:session_token])
        Current.session = session_record
      else
        redirect_to sign_in_path
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
end
