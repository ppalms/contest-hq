class UsersController < ApplicationController
  before_action :require_sysadmin

  def index
    @users = User.includes(:roles).all.order(:email)
    @users = @users.where("email ILIKE ?", "%#{params[:email]}%") if params[:email].present?
  end

  def edit
    @user = User.find(params[:id])
    @roles = Role.all
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.append("notifications", partial: "shared/notification", locals: { message: "Successfully updated user" }) }
        format.html { redirect_to users_path, notice: "User updated successfully." }
      end
    else
      render :edit
    end
  end

  private

  def require_sysadmin
    unless Current.user&.roles&.exists?(name: "SysAdmin")
      redirect_to root_path
    end
  end

  def user_params
    params.require(:user).permit(role_ids: [])
  end
end
