class ContestEntriesController < ApplicationController
  before_action :set_contest
  before_action :set_contest_entry, only: %i[ show destroy ]
  before_action :set_breadcrumbs

  def index
    if !current_user.manages_contest(@contest)
      redirect_to contests_path, alert: "You do not manage this contest."
    end

    @contest_entries = ContestEntry.all
  end

  def new
    @contest_entry = ContestEntry.new
    if current_user.conducted_ensembles.count == 1
      @contest_entry.large_ensemble = current_user.conducted_ensembles.first
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
    params.expect(contest_entry: [ :contest_id, :large_ensemble_id ])
  end

  def set_breadcrumbs
    add_breadcrumb("Contests", contests_path)
    add_breadcrumb(@contest.name, @contest)
    add_breadcrumb("Entries", contest_entries_path)
  end
end
