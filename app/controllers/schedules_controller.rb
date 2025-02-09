class SchedulesController < ApplicationController
  before_action :set_contest
  # before_action :authorize_manager!
  before_action :set_schedule
  before_action :set_breadcrumbs, except: [ :setup ]

  def index
  end

  def setup
    add_breadcrumb("Contests", contests_path)
    add_breadcrumb(@contest.name, @contest)
    add_breadcrumb("Schedule", contest_schedules_path(@contest))
    add_breadcrumb("Setup")
  end

  def show
    @rooms = @schedule.rooms.includes(:room_blocks)
    @sequence = @schedule.performance_sequence
  end

  def edit
    @days = @schedule.days
  end

  private

  def set_contest
    @contest = Contest.find(params[:contest_id])
  end

  def set_schedule
    @schedule = Schedule.includes(:performance_sequence).find_or_create_by(contest_id: params[:contest_id])
  end

  def authorize_manager!
    unless current_user.managed_contests.exists?(@contest.id)
      flash[:alert] = "You must be a manager of this contest to access this area"
      redirect_to root_path
    end
  end

  def set_breadcrumbs
    add_breadcrumb("Contests", contests_path)
    add_breadcrumb(@contest.name, @contest)
    add_breadcrumb("Schedule", contest_schedules_path(@contest))
  end
end
