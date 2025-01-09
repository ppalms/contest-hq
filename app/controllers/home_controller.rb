class HomeController < ApplicationController
  def index
    if current_user.sysadmin?
      @new_accounts = Account.order(created_at: :desc).limit(5)

      @active_sessions = User
        .joins(:sessions)
        .select("users.id, users.email, MAX(sessions.created_at) AS last_session_created_at")
        .group("users.id")
        .order("last_session_created_at DESC")
        .limit(5)
    end

    if current_user.tenant_admin?
      @new_users = User
        .select("users.id, users.email, users.created_at")
        .where(account: current_user.account)
        .where.not(
          id: User.joins(:roles).where(roles: { name: "SysAdmin" }).select(:id)
        )
        .includes(:roles)
        .order("users.created_at DESC")
        .limit(5)

      @schools = School.select("schools.id, schools.name").order("schools.name").limit(5)
    end

    if current_user.director?
      @my_entries = ContestEntry.where(user: current_user)
      @my_scores = []

      @upcoming_contests = Contest
        .order("contest_start")
        .limit(5)
    end

    if current_user.manager?
      @managed_contests = current_user.managed_contests
        .order("contest_start")
        .limit(5)
    end
  end

  def settings
  end
end
