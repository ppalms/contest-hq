class UsersController < ApplicationController
  before_action -> { require_role "SysAdmin", "AccountAdmin" }
  before_action :set_user, only: %i[edit update]

  def index
      @users = User
        .where.not(
          id: User.joins(:roles).where(roles: { name: "SysAdmin" }).select(:id)
        )
        .includes(:roles)
        .order(:last_name)

      @users = @users.where("email ILIKE ?", "%#{params[:email]}%") if params[:email].present?
  end

  def edit
    if current_user.account != @user.account && !current_user.sysadmin?
      redirect_to root_path, status: :forbidden; return
    end

    @roles = Role.where(name: %w[Director Manager Judge AccountAdmin]).order(:name)
    @organizations = School.all.order(:name)

    render :edit, locals: { roles: @roles, organizations: @organizations }
  end

  def update
    if current_user.account != @user.account && !current_user.sysadmin?
      redirect_to root_path, status: :forbidden; return
    end

    if @user.update(user_params)
      redirect_to users_path, notice: "User updated successfully."
    else
      render :edit, status: :unprocessable_content, error: "Failed to update user."
    end
  end

  private

  def user_params
    params.expect(user: [ :email, :first_name, :last_name, :time_zone, role_ids: [], school_ids: [] ])
  end

  def set_user
    @user = User.find(params[:id])
  end
end
