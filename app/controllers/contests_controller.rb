class ContestsController < ApplicationController
  before_action :set_contest, only: %i[ show edit update destroy setup schedule ]
  before_action :set_schedule, only: %i[ show schedule ]
  before_action -> { require_role "AccountAdmin" }, only: %i[ create destroy ]
  before_action :set_breadcrumbs

  # GET /contests or /contests.json
  def index
    @contests = Contest.all.order(:contest_start)
    @contests = @contests.where("name ILIKE ?", "%#{params[:name]}%") if params[:name].present?
  end

  # GET /contests/1 or /contests/1.json
  def show
  end

  # GET /contests/new
  def new
    @contest = Contest.new
  end

  # GET /contests/1/edit
  def edit
  end

  # POST /contests or /contests.json
  def create
    @contest = Contest.build(contest_params)

    respond_to do |format|
      if @contest.save
        format.html { redirect_to contest_url(@contest), notice: "Contest was successfully created." }
        format.json { render :show, status: :created, contest: @contest }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @contest.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /contests/1 or /contests/1.json
  def update
    respond_to do |format|
      if @contest.update(contest_params)
        format.html { redirect_to contest_url(@contest), notice: "Contest was successfully updated." }
        format.json { render :show, status: :ok, contest: @contest }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @contest.errors, status: :unprocessable_entity }
      end
    end
  end

  def schedule
  end

  # Set up contest performance phases
  def setup
    add_breadcrumb("Contests", contests_path)
    add_breadcrumb(@contest.name, @contest)
    add_breadcrumb("Setup")
  end

  # PATCH/PUT /contests/1/times or /contests/1/times.json
  def set_times
    @contest = Contest.find(params[:contest_id])
    respond_to do |format|
      if @contest.update(schedule_params)
        format.html { redirect_to contest_url(@contest), notice: "Contest times were successfully updated." }
        format.json { render :show, status: :ok, contest: @contest }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @contest.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contests/1 or /contests/1.json
  def destroy
    @contest.destroy!

    respond_to do |format|
      format.html { redirect_to contests_url, notice: "Contest was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_contest
    @contest = Contest.find(params[:id] || params[:contest_id])
  end

  def set_schedule
    @schedule = Schedule.find_by(contest_id: @contest.id)
  end

  def contest_params
    params.expect(contest: [ :name, :contest_start, :contest_end, school_class_ids: [] ])
  end

  def schedule_params
    params.expect(contest: [ :start_time, :end_time ])
  end

  def set_breadcrumbs
    add_breadcrumb("Contests", contests_path)
  end
end
