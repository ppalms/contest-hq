class UsersController < ApplicationController
  include Pagy::Method

  before_action -> { require_role "SysAdmin", "AccountAdmin" }
  before_action :set_user, only: %i[show edit update]
  before_action :set_breadcrumbs, only: %i[show edit]

  def index
    base_query = User
      .where.not(
        id: User.joins(:roles).where(roles: { name: "SysAdmin" }).select(:id)
      )
      .includes(:roles)
      .order(:last_name)

    search_query = base_query
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      search_query = search_query.where(
        "first_name LIKE ? OR last_name LIKE ? OR email LIKE ?",
        search_term, search_term, search_term
      )
    end

    @pagy, @users = pagy(search_query, limit: 6)
  end

  def show
    if current_user.account != @user.account && !current_user.sys_admin?
      redirect_to root_path, status: :forbidden; return
    end

    @roles = Role.where(name: %w[Director Manager Judge AccountAdmin]).order(:name)
    @organizations = School.all.order(:name)

    render :show, locals: { roles: @roles, organizations: @organizations }
  end

  def edit
    if current_user.account != @user.account && !current_user.sys_admin?
      redirect_to root_path, status: :forbidden; return
    end

    @roles = Role.where(name: %w[Director Manager Judge AccountAdmin]).order(:name)
    @organizations = School.all.order(:name)

    render :edit, locals: { roles: @roles, organizations: @organizations }
  end

  def update
    if current_user.account != @user.account && !current_user.sys_admin?
      redirect_to root_path, status: :forbidden; return
    end

    # Handle school removal
    if params[:user][:remove_school_id].present?
      school = School.find(params[:user][:remove_school_id])
      @user.schools.delete(school)
      redirect_to user_path(@user), notice: "#{school.name} removed successfully."
      return
    end

    if @user.update(user_params)
      redirect_to user_path(@user), notice: "User updated successfully."
    else
      render :edit, status: :unprocessable_content, error: "Failed to update user."
    end
  end

  private

  def user_params
    params.expect(user: [ :email, :first_name, :last_name, :time_zone, :remove_school_id, role_ids: [], school_ids: [] ])
  end

  def set_user
    @user = User.find(params[:id])
  end

  def set_breadcrumbs
    add_breadcrumb("Users", users_path)
    add_breadcrumb("#{@user.first_name} #{@user.last_name}", @user) if @user
  end
end
