class InvitationsController < ApplicationController
  def new
    @user = User.new
    if current_user.sysadmin?
      @roles = Role.where(name: %w[Director Judge TenantAdmin]).order(:name)
    else
      @roles = Role.where(name: %w[Director Judge]).order(:name)
    end
    @organizations = Organization.all.order(:name)

    render :new, locals: { roles: @roles, organizations: @organizations }
  end

  def create
    @user = User.create_with(user_params).find_or_initialize_by(email: user_params[:email])
    if @user.save
      send_invitation_instructions
      redirect_to new_invitation_path, notice: "An invitation email has been sent to #{@user.email}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: [ :email, :first_name, :last_name, :time_zone, role_ids: [], organization_ids: [] ]).merge(password: SecureRandom.base58, verified: true)
  end

  def send_invitation_instructions
    UserMailer.with(user: @user).invitation_instructions.deliver_later
  end
end
