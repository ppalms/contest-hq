class UsersController < ApplicationController
  before_action -> { require_role "SysAdmin", "TenantAdmin" }

  def index
      @users = User.includes(:roles).where.not(roles: { name: "SysAdmin" }).order(:last_name)
      @users = @users.where("email ILIKE ?", "%#{params[:email]}%") if params[:email].present?
  end

  def edit
    @user = User.find(params[:id])
    if current_user.sysadmin?
      @roles = Role.where(name: %w[Director Judge TenantAdmin]).order(:name)
    else
      @roles = Role.where(name: %w[Director Judge]).order(:name)
    end
    @organizations = Organization.all.order(:name)

    render :edit, locals: { roles: @roles, organizations: @organizations }
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      flash[:notice] = "Successfully updated user."
      redirect_to users_path, notice: "User updated successfully."
    else
      flash[:error] = "Failed to update user."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: [ :email, :first_name, :last_name, :time_zone, role_ids: [], organization_ids: [] ])
  end
end
