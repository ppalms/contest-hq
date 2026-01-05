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

    # Filter ensembles by contest school class eligibility
    @eligible_ensembles = eligible_ensembles_for_contest(current_user.conducted_ensembles, @contest)

    if @eligible_ensembles.empty?
      redirect_to @contest, alert: "None of your ensembles are eligible for this contest. This contest is restricted to #{@contest.school_classes.pluck(:name).join(', ')} schools."
      return
    end

    if @eligible_ensembles.count == 1
      @contest_entry.large_ensemble = @eligible_ensembles.first
    end

    if params[:large_ensemble_id].present?
      ensemble = @eligible_ensembles.find_by(id: params[:large_ensemble_id])
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
        # Set eligible ensembles for the form in case of validation errors
        @eligible_ensembles = eligible_ensembles_for_contest(current_user.conducted_ensembles, @contest)
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @contest_entry.errors, status: :unprocessable_content }
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
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @contest_entry.errors, status: :unprocessable_content }
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

  def select_prescribed_music
    @contest_entry = ContestEntry.find(params[:entry_id])
    @school_class = @contest_entry.large_ensemble.school.school_class
    @season = @contest_entry.contest.season

    scope = PrescribedMusic.for_season(@season.id).for_school_class(@school_class.id).by_title

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      scope = scope.where("title LIKE ? OR composer LIKE ?", search_term, search_term)
    end

    @prescribed_music = scope
    @current_selection = @contest_entry.music_selections.where.not(prescribed_music_id: nil).first
    add_breadcrumb(@contest_entry.large_ensemble.name, contest_entry_path(contest_id: @contest_entry.contest.id, id: @contest_entry.id))
    add_breadcrumb("Select Prescribed Music", "#")
  end

  def add_prescribed_music
    @contest_entry = ContestEntry.find(params[:entry_id])
    prescribed_music = PrescribedMusic.find(params[:prescribed_music_id])

    existing_prescribed = @contest_entry.music_selections.where.not(prescribed_music_id: nil).first

    if existing_prescribed
      existing_prescribed.update(
        prescribed_music: prescribed_music,
        title: prescribed_music.title,
        composer: prescribed_music.composer
      )
      flash[:notice] = "Prescribed music selection was updated."
    else
      @contest_entry.music_selections.create!(
        prescribed_music: prescribed_music,
        title: prescribed_music.title,
        composer: prescribed_music.composer
      )
      flash[:notice] = "Prescribed music was added to your contest entry."
    end

    redirect_to contest_entry_path(contest_id: @contest_entry.contest.id, id: @contest_entry.id)
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

  def eligible_ensembles_for_contest(ensembles, contest)
    # If contest has no school class restrictions, all ensembles are eligible
    return ensembles if contest.school_classes.empty?

    eligible_school_class_ids = contest.school_classes.pluck(:id)
    ensembles.joins(school: :school_class)
      .where(schools: { school_class_id: eligible_school_class_ids })
  end
end
