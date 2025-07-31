class ContestEntriesController < ApplicationController
  before_action :set_contest
  before_action :set_contest_entry, only: %i[ show edit update destroy ]
  before_action :set_breadcrumbs

  def index
    if !current_user.manages_contest(@contest)
      redirect_to contests_path, alert: "You do not manage this contest."
    end

    @contest_entries = ContestEntry.all
  end

  def new
    @contest_entry = ContestEntry.new

    if current_user.conducted_ensembles.count == 0
      redirect_to new_roster_large_ensemble_path(redirect_to_contest_entry: @contest.id), notice: "You need to create a large ensemble before registering for a contest."
      return
    end

    if current_user.conducted_ensembles.count == 1
      @contest_entry.large_ensemble = current_user.conducted_ensembles.first
    end

    if params[:large_ensemble_id].present?
      ensemble = current_user.conducted_ensembles.find_by(id: params[:large_ensemble_id])
      @contest_entry.large_ensemble = ensemble if ensemble
    end
  end

  def create
    @contest_entry = ContestEntry.new(contest_entry_params)
    @contest_entry.user = current_user

    if ContestEntry.where(contest: @contest_entry.contest, large_ensemble: @contest_entry.large_ensemble).exists?
      is_duplicate = true
      @contest_entry.errors.add(:base, "#{@contest_entry.large_ensemble.name} has already registered for #{@contest_entry.contest.name}.")
    end

    respond_to do |format|
      if !is_duplicate && @contest_entry.save
        format.html { redirect_to contest_entry_path(id: @contest_entry.id), notice: "Contest entry was successfully created." }
        format.json { render :show, status: :created, contest_entry: @contest_entry }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @contest_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
  end

  def edit
  end

  def update
    respond_to do |format|
      if @contest_entry.update(contest_entry_params)
        format.html { redirect_to contest_entry_path(id: @contest_entry.id), notice: "Contest entry was successfully updated." }
        format.json { render :show, status: :ok, contest_entry: @contest_entry }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @contest_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @contest_entry.destroy!

    respond_to do |format|
      format.html { redirect_to root_url, notice: "Contest entry was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_contest
    @contest = Contest.find(params[:contest_id])
  end

  def set_contest_entry
    @contest_entry = ContestEntry.find(params[:id])
  end

  def contest_entry_params
    params.expect(contest_entry: [ :contest_id, :large_ensemble_id, :preferred_time_start, :preferred_time_end ])
  end

  def set_breadcrumbs
    add_breadcrumb("Contests", contests_path)
    add_breadcrumb(@contest.name, @contest)
  end
end
