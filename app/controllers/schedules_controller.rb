class SchedulesController < ApplicationController
  # before_action :authorize_manager!
  before_action :set_schedule
  before_action :set_breadcrumbs

  def show
  end

  def edit
  end

  def generate
    entries = @schedule.contest.contest_entries
    entries.each do |entry|
      puts entry.inspect
    end
  end

  private

  def set_schedule
    @schedule = Schedule.find(params[:id])
  end

  def authorize_manager!
    unless current_user.managed_contests&.exists?(@schedule.contest.id)
      flash[:alert] = "You must be a manager of this contest to access this area"
      redirect_to root_path
    end
  end

  def set_breadcrumbs
    add_breadcrumb("Contests", contests_path)
    add_breadcrumb(@schedule.contest.name, @schedule.contest)
  end
end
