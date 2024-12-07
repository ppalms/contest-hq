class ContestGroupsController < ApplicationController
  before_action :set_contest_group, only: %i[show edit update destroy]
  before_action :set_breadcrumbs

  def index
    if index_params[:filter_current_user] == "false"
      @contest_groups = ContestGroup.includes(:contest_group_class).all
    else
      @contest_groups = current_user.conducted_groups.includes(:contest_group_class).all
    end
  end

  def show
  end

  def edit
    @contest_group_classes = ContestGroupClass.all
  end

  def new
    @contest_group = ContestGroup.new
    @contest_group_classes = ContestGroupClass.all
  end

  def create
    @contest_group = ContestGroup.new(contest_group_params)
    @contest_group_classes = ContestGroupClass.all

    if @contest_group.save
      redirect_to @contest_group, notice: "Contest group was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    respond_to do |format|
      if @contest_group.update(contest_group_params)
        format.html { redirect_to @contest_group, notice: "Contest group was successfully updated." }
        format.json { render :show, status: :ok, contest_group: @contest_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @contest_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @contest_group.destroy!

    respond_to do |format|
      format.html { redirect_to contest_groups_url, notice: "Contest group was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_contest_group
    @contest_group = ContestGroup.find(params[:id])
  end

  def contest_group_params
    params.expect(contest_group: [ :name, :contest_group_class_id, :organization_id ])
  end

  def index_params
    params.permit(:filter_current_user)
  end

  def set_breadcrumbs
    add_breadcrumb("Contest Groups", contest_groups_path)
  end
end
