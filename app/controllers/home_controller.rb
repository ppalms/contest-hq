class HomeController < ApplicationController
  def index
    if Current.user.sysadmin?
      @new_accounts = Account.order(created_at: :desc).limit(5)

      @recent_users = User
        .joins(:sessions)
        .select("users.id, users.email, MAX(sessions.created_at) AS last_session_created_at")
        .group("users.id")
        .order("last_session_created_at DESC")
        .limit(5)
    end

    if current_user.tenant_admin?
      @new_users = User
        .select("users.id, users.email, users.created_at")
        .order("users.created_at DESC")
        .limit(5)
    end

    if Current.user.director?
      @upcoming_contests = Contest
        .order("contest_start DESC")
        .limit(5)
    end
  end

  def settings
  end
end
