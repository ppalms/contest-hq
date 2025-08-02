class Roster::LargeEnsemblesController < ApplicationController
  before_action :set_large_ensemble, only: %i[show edit update destroy]
  before_action :set_performance_classes, only: %i[show edit new create]
  before_action :set_breadcrumbs

  def index
    if index_params[:filter_current_user] == "false"
      @large_ensembles = LargeEnsemble.includes(:performance_class).all
    else
      @large_ensembles = current_user.conducted_ensembles.includes(:performance_class).all
    end
  end

  def show
    @contests = Contest.left_outer_joins(:contests_school_classes)
      .where("contests_school_classes.school_class_id IS NULL OR contests_school_classes.school_class_id = ?", @large_ensemble.school.school_class.id)
      .distinct
  end

  def edit
  end

  def new
    @large_ensemble = LargeEnsemble.new

    if current_user.schools.length == 1
      @large_ensemble.school = current_user.schools.first
    end
  end

  def create
    @large_ensemble = LargeEnsemble.new(large_ensemble_params)

    if @large_ensemble.save
      # Check if we need to redirect back to contest entry creation
      if params[:redirect_to_contest_entry].present?
        contest_id = params[:redirect_to_contest_entry]
        redirect_to new_contest_entry_path(contest_id: contest_id, large_ensemble_id: @large_ensemble.id),
                    notice: "Large ensemble was successfully created. Now you can register for the contest."
      else
        redirect_to roster_large_ensemble_path(@large_ensemble), notice: "Large ensemble was successfully created."
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    respond_to do |format|
      if @large_ensemble.update(large_ensemble_params)
        format.html { redirect_to roster_large_ensemble_path(@large_ensemble), notice: "Large ensemble was successfully updated." }
        format.json { render :show, status: :ok, large_ensemble: @large_ensemble }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @large_ensemble.errors, status: :unprocessable_content }
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

    def set_performance_classes
      @performance_classes = PerformanceClass.in_order.all
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
