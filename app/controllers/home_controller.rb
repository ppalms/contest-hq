class HomeController < ApplicationController
  def index
    if Current.user.sysadmin?
      @new_accounts = Account.order(created_at: :desc).limit(5)
    end

    if Current.user.tenant_admin?
      @recent_users = User
        .joins(:sessions)
        .select("users.id, users.email, MAX(sessions.created_at) AS last_session_created_at")
        .group("users.id")
        .order("last_session_created_at DESC")
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
