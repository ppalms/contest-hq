class SchedulesController < ApplicationController
  before_action :set_schedule
  before_action :authorize_manager!, only: [ :generate, :reset, :reschedule, :update_schedule ]
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

    # Get current time slot information
    current_time_slot = nil
    current_day_id = nil
    if @current_blocks.any?
      first_block = @current_blocks.first
      current_time_slot = first_block.start_time.strftime("%H:%M:%S")
      current_day_id = first_block.schedule_day_id
    end

    @errors = {}
    @form_values = {
      target_day_id: @schedule_days.first&.id,
      target_time_slot: nil,
      reschedule_method: "swap"
    }

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("modal_container", partial: "schedules/reschedule_modal",
                            locals: { schedule: @schedule, contest_entry: @contest_entry,
                                    schedule_days: @schedule_days, current_blocks: @current_blocks,
                                    errors: @errors, form_values: @form_values,
                                    current_time_slot: current_time_slot, current_day_id: current_day_id })
        ]
      end
    end
  end

  def update_schedule
    @contest_entry = ContestEntry.find(params[:contest_entry_id])
    @schedule_days = @schedule.days
    @current_blocks = @contest_entry.schedule_blocks.includes(:schedule_day, :performance_phase)

    # Get current time slot information
    current_time_slot = nil
    current_day_id = nil
    if @current_blocks.any?
      first_block = @current_blocks.first
      current_time_slot = first_block.start_time.strftime("%H:%M:%S")
      current_day_id = first_block.schedule_day_id
    end

    @errors = {}
    @form_values = {
      target_day_id: params[:target_day_id],
      target_time_slot: params[:target_time_slot],
      reschedule_method: params[:reschedule_method]
    }

    # Validation checks
    if @schedule.contest.contest_start < DateTime.now
      @errors[:base] = "Contest has already started. Cannot reschedule."
    elsif params[:target_day_id].blank?
      @errors[:target_day_id] = "Please select a day"
    elsif params[:target_time_slot].blank?
      @errors[:target_time_slot] = "Please select a time slot"
    elsif current_day_id && current_time_slot &&
          params[:target_day_id].to_i == current_day_id &&
          params[:target_time_slot] == current_time_slot
      @errors[:target_time_slot] = "Cannot reschedule to the current time slot"
    else
      # Check if the selected time slot is occupied before requiring reschedule method
      target_day = @schedule.days.find(params[:target_day_id])
      time_parts = params[:target_time_slot].split(":")
      target_time = target_day.schedule_date.beginning_of_day +
                    time_parts[0].to_i.hours +
                    time_parts[1].to_i.minutes +
                    (time_parts[2] ? time_parts[2].to_i.seconds : 0)

      # Check if there's an existing entry at the target time
      existing_block = ScheduleBlock.where(
        account_id: Current.account.id,
        schedule_day_id: target_day.id
      ).where(
        "start_time <= ? AND end_time > ?", target_time, target_time
      ).first

      # Only require reschedule method if the time slot is occupied
      if existing_block && params[:reschedule_method].blank?
        @errors[:reschedule_method] = "Please select a reschedule method"
      end
    end

    if @errors.any?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("modal_container", partial: "schedules/reschedule_modal",
                              locals: { schedule: @schedule, contest_entry: @contest_entry,
                                      schedule_days: @schedule_days, current_blocks: @current_blocks,
                                      errors: @errors, form_values: @form_values,
                                      current_time_slot: current_time_slot, current_day_id: current_day_id })
          ]
        end
      end
      return
    end

    target_day = @schedule.days.find(params[:target_day_id])
    # Parse the time string and combine it with the target day's date
    time_parts = params[:target_time_slot].split(":")
    target_time = target_day.schedule_date.beginning_of_day +
                  time_parts[0].to_i.hours +
                  time_parts[1].to_i.minutes +
                  (time_parts[2] ? time_parts[2].to_i.seconds : 0)
    reschedule_method = params[:reschedule_method] # 'swap' or 'shift'

    begin
      # Check if target time slot is available
      existing_block = ScheduleBlock.where(
        account_id: Current.account.id,
        schedule_day_id: target_day.id
      ).where(
        "start_time <= ? AND end_time > ?", target_time, target_time
      ).first

      if existing_block.nil?
        # Target slot is available, just move the entry
        result = perform_simple_reschedule(@contest_entry, target_day, target_time)
      else
        # Target slot is occupied, use specified method
        case reschedule_method
        when "swap"
          result = perform_swap_reschedule(@contest_entry, target_day, target_time)
        when "shift"
          result = perform_shift_reschedule(@contest_entry, target_day, target_time)
        end
      end

      if result == false
        @errors[:base] = "Unable to reschedule to the selected time slot. Please try a different time or method."

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update("modal_container", partial: "schedules/reschedule_modal",
                                locals: { schedule: @schedule, contest_entry: @contest_entry,
                                        schedule_days: @schedule_days, current_blocks: @current_blocks,
                                        errors: @errors, form_values: @form_values,
                                        current_time_slot: current_time_slot, current_day_id: current_day_id })
            ]
          end
        end
        return
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
    rescue => e
      @errors[:base] = "An error occurred during rescheduling: #{e.message}"

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("modal_container", partial: "schedules/reschedule_modal",
                              locals: { schedule: @schedule, contest_entry: @contest_entry,
                                      schedule_days: @schedule_days, current_blocks: @current_blocks,
                                      errors: @errors, form_values: @form_values,
                                      current_time_slot: current_time_slot, current_day_id: current_day_id })
          ]
        end
      end
    end
  end

  def get_day_time_slots
    day = @schedule.days.find(params[:day_id])
    time_slots = []

    # Get contest entry if provided to identify current time slot
    contest_entry_id = params[:contest_entry_id]
    current_entry_time = nil
    if contest_entry_id
      contest_entry = ContestEntry.find(contest_entry_id)
      current_blocks = contest_entry.schedule_blocks.where(schedule_day_id: day.id)
      current_entry_time = current_blocks.first&.start_time
    end

    # Get all existing schedule blocks for this day, ordered by start time
    existing_blocks = day.schedule_blocks
                         .includes(contest_entry: { large_ensemble: [ :school, :performance_class ] })
                         .order(:start_time)

    # Calculate total duration of all performance phases for this contest
    total_phase_duration = @schedule.contest.performance_phases.sum(:duration)

    # Generate time slots using the total phase duration as interval
    current_time = day.start_time
    while current_time < day.end_time
      # Find any blocks that start at this time
      blocks_at_time = existing_blocks.select { |block| block.start_time == current_time }

      is_current_slot = current_entry_time && current_time == current_entry_time

      time_slot = {
        time: current_time.strftime("%H:%M"),
        time_value: current_time.strftime("%H:%M:%S"),
        display: current_time.strftime("%l:%M %p").strip,
        available: blocks_at_time.empty?,
        is_current: is_current_slot,
        entry: nil
      }

      if blocks_at_time.any?
        block = blocks_at_time.first
        entry = block.contest_entry
        time_slot[:entry] = {
          id: entry.id,
          name: entry.large_ensemble.name,
          school: entry.large_ensemble.school.name,
          performance_class: entry.large_ensemble.performance_class&.abbreviation
        }
      end

      time_slots << time_slot
      current_time += total_phase_duration.minutes
    end

    respond_to do |format|
      format.json { render json: { time_slots: time_slots } }
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
    unless current_user.manages_contest(@schedule.contest.id)
      flash[:alert] = "You must be a manager of this contest to access this area"
      redirect_to root_path
    end
  end

  def set_breadcrumbs
    add_breadcrumb("Contests", contests_path(season_id: @schedule.contest.season_id))
    add_breadcrumb(@schedule.contest.name, @schedule.contest)
  end

  def perform_simple_reschedule(contest_entry, target_day, target_time)
    # Simple move to an available time slot
    entry_blocks = contest_entry.schedule_blocks.includes(:performance_phase).order(:start_time)

    # Calculate the time difference
    original_start_time = entry_blocks.first.start_time
    time_difference = target_time - original_start_time

    # Update all blocks for this entry
    entry_blocks.each do |block|
      new_start_time = block.start_time + time_difference
      new_end_time = block.end_time + time_difference

      block.update!(
        schedule_day: target_day,
        start_time: new_start_time,
        end_time: new_end_time
      )
    end

    true
  end

  def perform_swap_reschedule(contest_entry, target_day, target_time)
    # Find the target entry at the specified time
    target_blocks = target_day.schedule_blocks
                              .where("start_time <= ? AND end_time > ?", target_time, target_time)
                              .includes(:contest_entry)

    return false if target_blocks.empty?

    target_entry = target_blocks.first.contest_entry
    return false if target_entry == contest_entry

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
      # Use update_columns to bypass validations during swap operation
      block.update_columns(
        start_time: block.start_time + time_offset,
        end_time: block.end_time + time_offset,
        schedule_day_id: target_day.id
      )
    end

    # Update target blocks to entry's original time
    time_offset = original_entry_start - target_first_block.start_time
    target_entry_blocks.each do |block|
      original_day = entry_first_block.schedule_day
      # Use update_columns to bypass validations during swap operation
      block.update_columns(
        start_time: block.start_time + time_offset,
        end_time: block.end_time + time_offset,
        schedule_day_id: original_day.id
      )
    end

    true
  end

  def perform_shift_reschedule(contest_entry, target_day, target_time)
    entry_blocks = contest_entry.schedule_blocks.includes(:performance_phase).order(:start_time)
    return false if entry_blocks.empty?

    # Calculate total duration of this entry's performance
    total_duration = entry_blocks.sum { |block| (block.end_time - block.start_time) }
    new_end_time = target_time + total_duration

    # Find all blocks that would overlap with the new time slot
    blocks_to_shift = target_day.schedule_blocks
                               .where("(start_time < ? AND end_time > ?) OR start_time >= ?",
                                      new_end_time, target_time, target_time)
                               .where.not(contest_entry: contest_entry)
                               .includes(:contest_entry, :performance_phase)
                               .order(:start_time)

    # Shift overlapping blocks forward
    blocks_to_shift.group_by(&:contest_entry).each do |other_entry, blocks|
      # Find the earliest start time for this entry that conflicts
      earliest_block = blocks.min_by(&:start_time)

      # If the earliest block starts before our new slot, shift to our end time
      # If it starts after our new slot, shift by our total duration
      if earliest_block.start_time < target_time
        time_offset = new_end_time - earliest_block.start_time
      else
        time_offset = total_duration
      end

      blocks.each do |block|
        # Use update_columns to bypass validations during shift operation
        block.update_columns(
          start_time: block.start_time + time_offset,
          end_time: block.end_time + time_offset
        )
      end
    end

    # Move the entry to the new time
    time_offset = target_time - entry_blocks.first.start_time
    entry_blocks.each do |block|
      # Use update_columns to bypass validations during shift operation
      block.update_columns(
        start_time: block.start_time + time_offset,
        end_time: block.end_time + time_offset,
        schedule_day_id: target_day.id
      )
    end

    true
  end
end
