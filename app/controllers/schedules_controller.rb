class SchedulesController < ApplicationController
  before_action :set_contest
  # before_action :authorize_manager!
  before_action :set_schedule, except: [ :index, :setup ]

  def index
  end

  def setup
    @schedule = Schedule.find_or_create_by(contest_id: params[:contest_id])
    # .includes(performance_sequence: { performance_steps: { room_block: :room } })
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
    @schedule = Schedule.find_or_create_by(contest_id: params[:contest_id])
  end

  def authorize_manager!
    unless current_user.managed_contests.exists?(@contest.id)
      flash[:alert] = "You must be a manager of this contest to access this area"
      redirect_to root_path
    end
  end
end


# class SchedulesController < ApplicationController
#   before_action :set_contest, :set_breadcrumbs
# 
#   def index
#     @schedule = Schedule.find_or_create_by(contest_id: params[:contest_id])
#     @new_performance_step = PerformanceStep.new
#   end
# 
#   def create
#     @schedule = Schedule.includes(:performance_sequence).find_by(contest_id: params[:contest_id])
#     # @schedule.initialize_days(params[:start_time], params[:end_time])
# 
#     new_performance_step = PerformanceStep.new(name: params.dig(:schedule, :performance_step, :name), ordinal: params.dig(:schedule, :performance_step, :ordinal))
#     @schedule.performance_sequence.performance_steps << new_performance_step
#     logger = Logger.new(STDOUT)
#     logger.info(@schedule.performance_sequence.performance_steps)
# 
#     respond_to do |format|
#       if @schedule.save!
#         format.html { redirect_to contest_schedules_path(@contest), notice: "Schedule was successfully initialized." }
#         format.json { render :index, status: :ok, schedule: @schedule }
#       else
#         format.html { render :edit, status: :unprocessable_entity }
#         format.json { render json: @schedule.errors, status: :unprocessable_entity }
#       end
#     end
#   end
# 
#   private
# 
#   def set_contest
#     @contest = Contest.find(params[:contest_id])
#   end
# 
#   def set_breadcrumbs
#     add_breadcrumb("Contests", contests_path)
#     add_breadcrumb(@contest.name, contest_path(@contest))
#   end
# end
