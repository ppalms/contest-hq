class Roster::LargeEnsemblesController < ApplicationController
  before_action :set_large_ensemble, only: %i[show edit update destroy]
  before_action :set_breadcrumbs

  def index
    if index_params[:filter_current_user] == "false"
      @large_ensembles = LargeEnsemble.includes(:performance_class).all
    else
      @large_ensembles = current_user.conducted_ensembles.includes(:performance_class).all
    end
  end

  def show
    @contests = Contest.joins(:contests_school_classes)
      .where(contests_school_classes: { school_class_id: @large_ensemble.school.school_class.id })
      .distinct
  end

  def edit
    @performance_classes = PerformanceClass.all
  end

  def new
    @large_ensemble = LargeEnsemble.new
    @performance_classes = PerformanceClass.all

    if current_user.schools.length == 1
      @large_ensemble.school = current_user.schools.first
    end
  end

  def create
    @large_ensemble = LargeEnsemble.new(large_ensemble_params)
    @performance_classes = PerformanceClass.all

    if @large_ensemble.save
      redirect_to roster_large_ensemble_path(@large_ensemble), notice: "Large ensemble was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    respond_to do |format|
      if @large_ensemble.update(large_ensemble_params)
        format.html { redirect_to roster_large_ensemble_path(@large_ensemble), notice: "Large ensemble was successfully updated." }
        format.json { render :show, status: :ok, large_ensemble: @large_ensemble }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @large_ensemble.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @large_ensemble.destroy!

    respond_to do |format|
      format.html { redirect_to roster_large_ensembles_url, notice: "Large ensemble was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

    def set_large_ensemble
      @large_ensemble = LargeEnsemble.find(params[:id])
    end

    def large_ensemble_params
      params.expect(large_ensemble: [ :name, :performance_class_id, :school_id ])
    end

    def index_params
      params.permit(:filter_current_user)
    end

    def set_breadcrumbs
      add_breadcrumb("Roster", roster_path)
      add_breadcrumb("Large Ensembles", roster_large_ensembles_path)
    end
end
