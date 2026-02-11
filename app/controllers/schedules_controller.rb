class SchedulesController < ApplicationController
  before_action :set_schedule
  before_action :set_contest_entry, only: [ :reschedule, :update_schedule ]
  before_action :authorize_view_access!, only: [ :show ]
  before_action :authorize_manager!, only: [ :generate, :reset, :reschedule, :update_schedule ]
  before_action :set_breadcrumbs, only: [ :show, :reschedule ]

  def show
    @selected_day = params[:day_id] ? @schedule.days.find(params[:day_id]) : @schedule.days.first
  end

  def edit
  end

  def generate
    start_time = DateTime.parse(params[:start_time]).utc
    end_time = DateTime.parse(params[:end_time]).utc

    service = ScheduleGenerationService.new(@schedule, start_time, end_time)
    service.call

    respond_to do |format|
      format.turbo_stream do
        flash[:notice] = "Generated contest schedule."

        render turbo_stream: [
          turbo_stream.append("notifications", partial: "shared/notification"),
          turbo_stream.replace("schedule_day_content", partial: "schedules/days/schedule_blocks", locals: { schedule: @schedule, selected_day: @schedule.days.first }),
          turbo_stream.replace("contest_setup_content", partial: "contests/schedule_content", locals: { schedule: @schedule })
        ]

        flash.discard(:notice)
      end
      format.html do
        flash[:notice] = "Generated contest schedule."
        redirect_to @schedule
      end
    end
  rescue ScheduleGenerationService::GenerationError => e
    respond_to do |format|
      format.turbo_stream do
        flash[:alert] = e.message

        render turbo_stream: [
          turbo_stream.append("notifications", partial: "shared/notification")
        ]

        flash.discard(:alert)
      end
      format.html do
        flash[:alert] = e.message
        redirect_to @schedule
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
        format.html do
          flash[:alert] = "Contest has already started. Cannot reset schedule."
          redirect_to @schedule
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
          turbo_stream.replace("contest_setup_content", partial: "contests/schedule_content", locals: { schedule: @schedule })
        ]

        flash.discard(:notice)
      end
      format.html do
        flash[:notice] = "Reset contest schedule."
        redirect_to @schedule
      end
    end
  end

  def reschedule
    @schedule_days = @schedule.days
    @current_blocks = @contest_entry.schedule_blocks.includes(:schedule_day, :performance_phase)

    @current_time_slot = nil
    @current_day_id = nil
    if @current_blocks.any?
      first_block = @current_blocks.first
      @current_time_slot = first_block.start_time.strftime("%H:%M:%S")
      @current_day_id = first_block.schedule_day_id
    end

    @form_values = {
      target_day_id: @schedule_days.first&.id,
      target_time_slot: nil,
      reschedule_method: "swap"
    }
  end

  def update_schedule
    @schedule_days = @schedule.days
    @current_blocks = @contest_entry.schedule_blocks.includes(:schedule_day, :performance_phase)

    current_time_slot = nil
    current_day_id = nil
    if @current_blocks.any?
      first_block = @current_blocks.first
      current_time_slot = first_block.start_time.strftime("%H:%M:%S")
      current_day_id = first_block.schedule_day_id
    end

    @current_time_slot = current_time_slot
    @current_day_id = current_day_id

    @form_values = {
      target_day_id: params[:target_day_id],
      target_time_slot: params[:target_time_slot],
      reschedule_method: params[:reschedule_method]
    }

    if @schedule.contest.contest_start < DateTime.now
      @contest_entry.errors.add(:base, "Contest has already started. Cannot reschedule.")
    elsif params[:target_day_id].blank?
      @contest_entry.errors.add(:target_day_id, "Please select a day")
    elsif params[:target_time_slot].blank?
      @contest_entry.errors.add(:target_time_slot, "Please select a time slot")
    elsif current_day_id && current_time_slot &&
          params[:target_day_id].to_i == current_day_id &&
          params[:target_time_slot] == current_time_slot
      @contest_entry.errors.add(:target_time_slot, "Cannot reschedule to the current time slot")
    else
      target_day, target_time = parse_target_time_from_params

      existing_block = ScheduleBlock.where(
        account_id: @schedule.account.id,
        schedule_day_id: target_day.id
      ).where(
        "start_time <= ? AND end_time > ?", target_time, target_time
      ).first

      if existing_block && params[:reschedule_method].blank?
        @contest_entry.errors.add(:reschedule_method, "Please select a reschedule method (swap or shift)")
      end
    end

    if @contest_entry.errors.any?
      render :reschedule, status: :unprocessable_entity
      return
    end

    target_day, target_time = parse_target_time_from_params
    reschedule_method = params[:reschedule_method]

    begin
      existing_block = ScheduleBlock.where(
        account_id: @schedule.account.id,
        schedule_day_id: target_day.id
      ).where(
        "start_time <= ? AND end_time > ?", target_time, target_time
      ).first

      if existing_block.nil?
        result = perform_simple_reschedule(@contest_entry, target_day, target_time)
        flash[:notice] = "Successfully rescheduled #{@contest_entry.large_ensemble.name} to #{target_time.strftime('%a %-m/%d %l:%M %p')}."
      else
        case reschedule_method
        when "swap"
          result = perform_swap_reschedule(@contest_entry, target_day, target_time)
          other_entry = existing_block.contest_entry
          flash[:notice] = "Successfully swapped time slots between #{@contest_entry.large_ensemble.name} and #{other_entry.large_ensemble.name}."
        when "shift"
          result = perform_shift_reschedule(@contest_entry, target_day, target_time)
          flash[:notice] = "Successfully rescheduled #{@contest_entry.large_ensemble.name} and shifted subsequent entries."
        end
      end

      if result == false
        @contest_entry.errors.add(:base, "Unable to reschedule to the selected time slot. The time slot may conflict with existing entries or exceed the day's time boundaries. Please try a different time or method.")
        render :reschedule, status: :unprocessable_entity
        return
      end

      redirect_to schedule_path(@schedule, anchor: "entry_#{@contest_entry.id}")

    rescue ActiveRecord::RecordInvalid => e
      @contest_entry.errors.add(:base, "Validation error: #{e.message}")
      render :reschedule, status: :unprocessable_entity
    rescue => e
      @contest_entry.errors.add(:base, "An unexpected error occurred during rescheduling: #{e.message}. Please try again or contact support if the problem persists.")
      render :reschedule, status: :unprocessable_entity
    end
  end

  def get_day_time_slots
    day = @schedule.days.find(params[:day_id])
    time_slots = []

    # Get contest entry if provided to identify current time slot and include preferred times
    contest_entry_id = params[:contest_entry_id]
    current_entry_time = nil
    current_entry = nil
    if contest_entry_id
      current_entry = ContestEntry.find(contest_entry_id)
      current_blocks = current_entry.schedule_blocks.where(schedule_day_id: day.id)
      current_entry_time = current_blocks.first&.start_time
    end

    # Get all existing schedule blocks for this day, ordered by start time
    existing_blocks = day.schedule_blocks
                         .includes(contest_entry: { large_ensemble: [ :school, :performance_class ] })
                         .order(:start_time)

    # Calculate total duration of all performance phases for this contest
    total_phase_duration = @schedule.contest.performance_phases.sum(:duration)

    # Helper method to format preferred times
    def format_preferred_times(entry)
      return nil unless entry.has_time_preference?

      if entry.full_time_preference?
        "#{entry.preferred_time_start.strftime('%l:%M %p').strip} - #{entry.preferred_time_end.strftime('%l:%M %p').strip}"
      elsif entry.preferred_time_start.present?
        "After #{entry.preferred_time_start.strftime('%l:%M %p').strip}"
      elsif entry.preferred_time_end.present?
        "Before #{entry.preferred_time_end.strftime('%l:%M %p').strip}"
      end
    end

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
        entry: nil,
        current_entry_preferred_times: current_entry ? format_preferred_times(current_entry) : nil
      }

      if blocks_at_time.any?
        block = blocks_at_time.first
        entry = block.contest_entry
        time_slot[:entry] = {
          id: entry.id,
          name: entry.large_ensemble.name,
          school: entry.large_ensemble.school.name,
          performance_class: entry.large_ensemble.performance_class&.abbreviation,
          preferred_times: format_preferred_times(entry)
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

  def set_contest_entry
    @contest_entry = ContestEntry.find(params[:contest_entry_id])
  end

  def authorize_manager!
    unless current_user.manages_contest(@schedule.contest.id)
      flash[:alert] = "You must be a manager of this contest to access this area"
      redirect_to root_path
    end
  end

  def authorize_view_access!
    # Allow sysadmins and tenant admins to view any schedule
    return if current_user.admin?

    # Allow contest managers to view schedules for contests they manage
    return if current_user.manages_contest(@schedule.contest.id)

    # Allow directors to view schedules for contests they have entries in
    if current_user.director?
      return if @schedule.contest.contest_entries.where(user_id: current_user.id).exists?
    end

    flash[:alert] = "You do not have permission to view this schedule"
    redirect_to root_path
  end

  def set_breadcrumbs
    add_breadcrumb("Contests", contests_path(season_id: @schedule.contest.season_id))
    add_breadcrumb(@schedule.contest.name, @schedule.contest)

    if action_name == "reschedule"
      add_breadcrumb("Schedule", schedule_path(@schedule))
      add_breadcrumb("Reschedule", reschedule_entry_path(@schedule, @contest_entry))
    elsif action_name == "show"
      add_breadcrumb("Schedule", schedule_path(@schedule))
    end
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

  def parse_target_time_from_params
    return [ nil, nil ] if params[:target_day_id].blank? || params[:target_time_slot].blank?

    target_day = @schedule.days.find(params[:target_day_id])
    time_parts = params[:target_time_slot].split(":")
    target_time = target_day.schedule_date.beginning_of_day +
                  time_parts[0].to_i.hours +
                  time_parts[1].to_i.minutes +
                  (time_parts[2] ? time_parts[2].to_i.seconds : 0)

    [ target_day, target_time ]
  end
end
