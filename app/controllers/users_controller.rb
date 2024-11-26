class UsersController < ApplicationController
  before_action -> { require_role "SysAdmin" }

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
      flash[:notice] = "Successfully updated user."
      redirect_to users_path, notice: "User updated successfully."
    else
      flash[:error] = "Failed to update user."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :time_zone, role_ids: [])
  end
end
