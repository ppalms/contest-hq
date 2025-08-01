class InvitationsController < ApplicationController
  def new
    @user = User.new
    set_form_variables
    render :new, locals: { roles: @roles, organizations: @organizations }
  end

  def create
    @user = User.create_with(user_params).find_or_initialize_by(email: user_params[:email])
    if @user.save
      send_invitation_instructions
      redirect_to new_invitation_path, notice: "An invitation email has been sent to #{@user.email}"
    else
      set_form_variables
      render :new, status: :unprocessable_content, locals: { roles: @roles, organizations: @organizations }
    end
  end

  private

  def user_params
    params.expect(user: [ :email, :first_name, :last_name, :time_zone, role_ids: [], school_ids: [] ]).merge(password: SecureRandom.base58, verified: true)
  end

  def set_form_variables
    if current_user.sysadmin?
      @roles = Role.where(name: %w[Director Judge Manager AccountAdmin]).order(:name)
    elsif current_user.tenant_admin?
      @roles = Role.where(name: %w[Director Judge Manager]).order(:name)
    else
      @roles = Role.where(name: %w[Director Judge]).order(:name)
    end
    @organizations = School.all.order(:name)
  end

  def send_invitation_instructions
    UserMailer.with(user: @user).invitation_instructions.deliver_later
  end
end
