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

      @organizations = Organization.select("organizations.id, organizations.name").order("organizations.name").limit(5)
    end

    # TODO: show contests director has registered for
    if current_user.director?
      @my_groups = ContestGroup.includes(:contest_group_class)

      @upcoming_contests = Contest
        .order("contest_start")
        .limit(5)
    end

    if current_user.scheduler?
      @managed_contests = Contest
        .order("contest_start")
        .limit(5)
    end
  end

  def settings
  end
end
