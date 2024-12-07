class OrganizationsController < ApplicationController
  before_action :set_organization, only: [ :show, :edit, :update, :destroy ]
  before_action :set_breadcrumbs

  def index
    @organizations = Organization.includes(:organization_type).all.order(:name)
  end

  def new
    if !current_user.admin?
      redirect_to organizations_path, alert: "You do not have permission to create organizations."
    end

    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)
    if @organization.save
      redirect_to organizations_path, notice: "Organization was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    respond_to do |format|
      if @organization.update(organization_params)
        format.html { redirect_to organization_url(@organization), notice: "Organization was successfully updated." }
        format.json { render :show, status: :ok, organization: @organization }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @organization.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @organization.destroy!

    respond_to do |format|
      format.html { redirect_to organizations_path, notice: "Organization was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def organization_params
    params.expect(organization: [ :name, :organization_type_id ])
  end

  def set_breadcrumbs
    add_breadcrumb("Organizations", organizations_path)
  end
end
