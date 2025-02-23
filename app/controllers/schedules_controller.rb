class SchedulesController < ApplicationController
  # before_action :authorize_manager!
  before_action :set_schedule
  before_action :set_breadcrumbs

  def show
  end

  def edit
  end

  # TODO: move to helper
  def generate
    start_time = DateTime.parse(params[:start_time]).utc
    end_time = DateTime.parse(params[:end_time]).utc

    @schedule.initialize_days(start_time, end_time)

    # Create schedule blocks for each entry based on contest performance phases
    #
    # Each contest entry should have a schedule block for each phase
    # Schedule blocks cannot overlap within a room
    # No gaps between schedule blocks for each entry
    # There may be gaps between entries

    entries = @schedule.contest.contest_entries.in_order
    current_day = @schedule.days.first

    entries.each_with_index do |entry, index|
      increment_day = index > 0 && index % 20 == 0
      if increment_day == true
        next_day = @schedule.days.find_by(schedule_date: current_day.schedule_date + 1)
        if next_day != nil
          current_day = next_day
        end
      end

      if index == 0 || increment_day == true
        start_time = current_day.start_time
      else
        start_time = entries[index - 1].schedule_blocks.in_order.last.end_time
      end

      phase_start = start_time

      @schedule.contest.performance_phases.each do |phase|
        block = ScheduleBlock.new(
          schedule_day: current_day,
          room: phase.room,
          contest_entry: entry,
          performance_phase: phase,
          start_time: phase_start,
          end_time: phase_start + phase.duration.minutes
        )
        block.save

        phase_start = block.end_time
      end
    end

    respond_to do |format|
      format.turbo_stream do
        flash[:notice] = "Generated contest schedule."

        render turbo_stream: [
          turbo_stream.append("notifications", partial: "shared/notification"),
          turbo_stream.replace("schedule_day_content", partial: "schedules/days/schedule_blocks", locals: { day: @schedule.days.first })
        ]

        flash.discard(:notice)
      end
    end
  end

  def reset
    @schedule.schedule_days.destroy_all

    respond_to do |format|
      format.turbo_stream do
        flash[:notice] = "Reset contest schedule."

        render turbo_stream: [
          turbo_stream.append("notifications", partial: "shared/notification"),
          turbo_stream.replace("schedule_day_content", partial: "schedules/days/schedule_blocks", locals: { day: nil })
        ]

        flash.discard(:notice)
      end
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
