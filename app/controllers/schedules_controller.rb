class SchedulesController < ApplicationController
  before_action :authorize_manager!, only: [ :generate, :reset, :reschedule, :update_schedule ]
  before_action :set_schedule
  before_action :set_breadcrumbs

  def show
    @selected_day = params[:day_id] ? @schedule.days.find(params[:day_id]) : @schedule.days.first
  end

  def edit
  end

  # TODO: move to helper
  def generate
    if @schedule.contest.contest_start < DateTime.now
      respond_to do |format|
        format.turbo_stream do
        flash[:alert] = "Contest has already started. Cannot generate schedule."

        render turbo_stream: [
          turbo_stream.append("notifications", partial: "shared/notification")
        ]

        flash.discard(:alert)
        end
      end
      return
    end

    start_time = DateTime.parse(params[:start_time]).utc
    end_time = DateTime.parse(params[:end_time]).utc

    @schedule.initialize_days(start_time, end_time)

    # Create schedule blocks for each entry based on contest performance phases
    #
    # TODO: write tests
    # Each contest entry should have a schedule block for each phase
    # Schedule blocks cannot overlap within a room
    # No gaps between schedule blocks for each entry
    # There may be gaps between entries

    entries = @schedule.contest.contest_entries.performance_order
    current_day = @schedule.days.first

    entries.each_with_index do |entry, index|
      # TODO: increment day based on performance end time
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
        start_time = entries[index - 1].schedule_blocks.by_start_time.last&.end_time
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
          turbo_stream.replace("schedule_day_content", partial: "schedules/days/schedule_blocks", locals: { schedule: @schedule, selected_day: @schedule.days.first }),
          turbo_stream.replace("schedule_action_content", partial: "schedules/action_buttons", locals: { schedule: @schedule })
        ]

        flash.discard(:notice)
      end
    end
  end

  def reset
    if @schedule.contest.contest_start < DateTime.now
      respond_to do |format|
        format.turbo_stream do
        flash[:alert] = "Contest has already started. Cannot reset schedule."

        render turbo_stream: [
          turbo_stream.append("notifications", partial: "shared/notification")
        ]

        flash.discard(:alert)
        end
      end
      return
    end

    @schedule.schedule_days.destroy_all

    respond_to do |format|
      format.turbo_stream do
        flash[:notice] = "Reset contest schedule."

        render turbo_stream: [
          turbo_stream.append("notifications", partial: "shared/notification"),
          turbo_stream.replace("schedule_day_content", partial: "schedules/days/schedule_blocks", locals: { schedule: @schedule, selected_day: nil }),
          turbo_stream.replace("schedule_action_content", partial: "schedules/action_buttons", locals: { schedule: @schedule })
        ]

        flash.discard(:notice)
      end
    end
  end

  def reschedule
    @contest_entry = ContestEntry.find(params[:contest_entry_id])
    @schedule_days = @schedule.days
    @current_blocks = @contest_entry.schedule_blocks.includes(:schedule_day, :performance_phase)
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("modal_container", partial: "schedules/reschedule_modal", 
                            locals: { schedule: @schedule, contest_entry: @contest_entry, 
                                    schedule_days: @schedule_days, current_blocks: @current_blocks })
        ]
      end
    end
  end

  def update_schedule
    @contest_entry = ContestEntry.find(params[:contest_entry_id])
    target_day = @schedule.days.find(params[:target_day_id])
    target_time = Time.parse(params[:target_time])
    reschedule_method = params[:reschedule_method] # 'swap' or 'shift'

    if @schedule.contest.contest_start < DateTime.now
      respond_to do |format|
        format.turbo_stream do
          flash[:alert] = "Contest has already started. Cannot reschedule."
          render turbo_stream: [
            turbo_stream.append("notifications", partial: "shared/notification")
          ]
          flash.discard(:alert)
        end
      end
      return
    end

    case reschedule_method
    when 'swap'
      perform_swap_reschedule(@contest_entry, target_day, target_time)
    when 'shift'
      perform_shift_reschedule(@contest_entry, target_day, target_time)
    end

    respond_to do |format|
      format.turbo_stream do
        flash[:notice] = "Successfully rescheduled #{@contest_entry.large_ensemble.name}."
        
        # Find the day containing the moved entry for redirection
        updated_day = @contest_entry.schedule_blocks.first&.schedule_day

        render turbo_stream: [
          turbo_stream.append("notifications", partial: "shared/notification"),
          turbo_stream.replace("schedule_day_content", partial: "schedules/days/schedule_blocks", 
                              locals: { schedule: @schedule, selected_day: updated_day }),
          turbo_stream.update("modal_container", "")
        ]

        flash.discard(:notice)
      end
    end
  end

  private

  def set_schedule
    @schedule = Schedule.includes(
      contest: {
        performance_phases: [ :room ]
      },
      schedule_days: {
        schedule_blocks: [
          :performance_phase,
          :room,
          contest_entry: {
            large_ensemble: [ :school, :performance_class ]
          }
        ]
      }
    ).find(params[:id])
  end

  def authorize_manager!
    # TODO: add contest/user association
    unless current_user.manager?
      flash[:alert] = "You must be a manager of this contest to access this area"
      redirect_to root_path
    end
  end

  def set_breadcrumbs
    add_breadcrumb("Contests", contests_path)
    add_breadcrumb(@schedule.contest.name, @schedule.contest)
  end

  def perform_swap_reschedule(contest_entry, target_day, target_time)
    # Find the target entry at the specified time
    target_blocks = target_day.schedule_blocks
                              .where("start_time <= ? AND end_time > ?", target_time, target_time)
                              .includes(:contest_entry)

    return if target_blocks.empty?

    target_entry = target_blocks.first.contest_entry
    return if target_entry == contest_entry

    # Get all blocks for both entries
    entry_blocks = contest_entry.schedule_blocks.includes(:performance_phase).order(:start_time)
    target_entry_blocks = target_entry.schedule_blocks.includes(:performance_phase).order(:start_time)

    # Swap the start times
    entry_first_block = entry_blocks.first
    target_first_block = target_entry_blocks.first

    original_entry_start = entry_first_block.start_time
    original_target_start = target_first_block.start_time

    # Update entry blocks to target's original time
    time_offset = original_target_start - entry_first_block.start_time
    entry_blocks.each do |block|
      block.update!(
        start_time: block.start_time + time_offset,
        end_time: block.end_time + time_offset,
        schedule_day: target_day
      )
    end

    # Update target blocks to entry's original time
    time_offset = original_entry_start - target_first_block.start_time
    target_entry_blocks.each do |block|
      original_day = entry_first_block.schedule_day
      block.update!(
        start_time: block.start_time + time_offset,
        end_time: block.end_time + time_offset,
        schedule_day: original_day
      )
    end
  end

  def perform_shift_reschedule(contest_entry, target_day, target_time)
    entry_blocks = contest_entry.schedule_blocks.includes(:performance_phase).order(:start_time)
    return if entry_blocks.empty?

    first_block = entry_blocks.first
    original_start = first_block.start_time
    
    # Calculate total duration of this entry's performance
    total_duration = entry_blocks.sum { |block| (block.end_time - block.start_time) }
    
    # Find blocks that need to be shifted
    blocks_to_shift = target_day.schedule_blocks
                               .where("start_time >= ?", target_time)
                               .where.not(contest_entry: contest_entry)
                               .includes(:contest_entry, :performance_phase)
                               .order(:start_time)

    # Shift existing blocks after the target time
    blocks_to_shift.group_by(&:contest_entry).each do |entry, blocks|
      time_offset = total_duration
      blocks.each do |block|
        block.update!(
          start_time: block.start_time + time_offset,
          end_time: block.end_time + time_offset
        )
      end
    end

    # Move the entry to the new time
    time_offset = target_time - original_start
    entry_blocks.each do |block|
      block.update!(
        start_time: block.start_time + time_offset,
        end_time: block.end_time + time_offset,
        schedule_day: target_day
      )
    end
  end
end
