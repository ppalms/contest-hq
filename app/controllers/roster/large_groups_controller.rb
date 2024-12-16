class Roster::LargeGroupsController < ApplicationController
  before_action :set_large_group, only: %i[show edit update destroy]
  before_action :set_breadcrumbs

  def index
    if index_params[:filter_current_user] == "false"
      @large_groups = LargeGroup.includes(:large_group_class).all
    else
      @large_groups = current_user.conducted_groups.includes(:large_group_class).all
    end
  end

  def show
  end

  def edit
    @large_group_classes = LargeGroupClass.all
  end

  def new
    @large_group = LargeGroup.new
    @large_group_classes = LargeGroupClass.all

    if current_user.organizations.length == 1
      @large_group.organization = current_user.organizations.first
    end
  end

  def create
    @large_group = LargeGroup.new(large_group_params)
    @large_group_classes = LargeGroupClass.all

    if @large_group.save
      redirect_to roster_large_group_path(@large_group), notice: "Large ensemble was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    respond_to do |format|
      if @large_group.update(large_group_params)
        format.html { redirect_to roster_large_group_path(@large_group), notice: "Large ensemble was successfully updated." }
        format.json { render :show, status: :ok, large_group: @large_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @large_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @large_group.destroy!

    respond_to do |format|
      format.html { redirect_to roster_large_groups_url, notice: "Large ensemble was successfully deleted." }
      format.json { head :no_content }
    end
  end

    private

    def set_large_group
      @large_group = LargeGroup.find(params[:id])
    end

    def large_group_params
      params.expect(large_group: [ :name, :large_group_class_id, :organization_id ])
    end

    def index_params
      params.permit(:filter_current_user)
    end

    def set_breadcrumbs
      add_breadcrumb("Roster", roster_path)
      add_breadcrumb("Large Ensembles", roster_large_groups_path)
    end
end
