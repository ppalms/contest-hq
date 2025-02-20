class Organizations::SchoolsController < ApplicationController
  include Pagy::Backend

  before_action :set_school, only: [ :show, :edit, :update, :destroy ]
  before_action :set_breadcrumbs

  def index
    @pagy, @schools = pagy(School.where("name ILIKE ?", "%#{params[:name]}%"), limit: 6)
  end

  def new
    if !current_user.admin?
      redirect_to organizations_schools_path, alert: "You do not have permission to create schools."
    end

    @school = School.new
  end

  def create
    @school = School.new(school_params)
    if @school.save
      redirect_to organizations_schools_path, notice: "School was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    respond_to do |format|
      if @school.update(school_params)
        format.html { redirect_to organizations_school_url(@school), notice: "School was successfully updated." }
        format.json { render :show, status: :ok, school: @school }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @school.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @school.destroy!

    respond_to do |format|
      format.html { redirect_to organizations_schools_path, notice: "School was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_school
    @school = School.find(params[:id])
  end

  def school_params
    params.expect(school: [ :name, :school_class_id ])
  end

  def set_breadcrumbs
    add_breadcrumb("Organizations", organizations_path)
    add_breadcrumb("Schools", organizations_schools_path)
  end
end
