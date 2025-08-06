class SchedulesController < ApplicationController
  before_action :authorize_manager!, only: [ :generate, :reset, :move_entry_up, :move_entry_down, :swap_entries ]
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

  def move_entry_up
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

    contest_entry = @schedule.contest.contest_entries.find(params[:contest_entry_id])
    
    if move_entry_earlier(contest_entry)
      respond_to do |format|
        format.turbo_stream do
          flash[:notice] = "#{contest_entry.large_ensemble.name} moved up in schedule."
          selected_day = find_day_for_entry(contest_entry)
          
          render turbo_stream: [
            turbo_stream.append("notifications", partial: "shared/notification"),
            turbo_stream.replace("schedule_day_content", partial: "schedules/days/schedule_blocks", locals: { schedule: @schedule, selected_day: selected_day })
          ]
          flash.discard(:notice)
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          flash[:alert] = "Could not move #{contest_entry.large_ensemble.name} up in schedule."
          render turbo_stream: [
            turbo_stream.append("notifications", partial: "shared/notification")
          ]
          flash.discard(:alert)
        end
      end
    end
  end

  def move_entry_down
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

    contest_entry = @schedule.contest.contest_entries.find(params[:contest_entry_id])
    
    if move_entry_later(contest_entry)
      respond_to do |format|
        format.turbo_stream do
          flash[:notice] = "#{contest_entry.large_ensemble.name} moved down in schedule."
          selected_day = find_day_for_entry(contest_entry)
          
          render turbo_stream: [
            turbo_stream.append("notifications", partial: "shared/notification"),
            turbo_stream.replace("schedule_day_content", partial: "schedules/days/schedule_blocks", locals: { schedule: @schedule, selected_day: selected_day })
          ]
          flash.discard(:notice)
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          flash[:alert] = "Could not move #{contest_entry.large_ensemble.name} down in schedule."
          render turbo_stream: [
            turbo_stream.append("notifications", partial: "shared/notification")
          ]
          flash.discard(:alert)
        end
      end
    end
  end

  def swap_entries
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

    contest_entry = @schedule.contest.contest_entries.find(params[:contest_entry_id])
    target_entry = @schedule.contest.contest_entries.find(params[:target_entry_id])
    
    if swap_entry_times(contest_entry, target_entry)
      respond_to do |format|
        format.turbo_stream do
          flash[:notice] = "Swapped #{contest_entry.large_ensemble.name} with #{target_entry.large_ensemble.name}."
          selected_day = find_day_for_entry(contest_entry)
          
          render turbo_stream: [
            turbo_stream.append("notifications", partial: "shared/notification"),
            turbo_stream.replace("schedule_day_content", partial: "schedules/days/schedule_blocks", locals: { schedule: @schedule, selected_day: selected_day })
          ]
          flash.discard(:notice)
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          flash[:alert] = "Could not swap #{contest_entry.large_ensemble.name} with #{target_entry.large_ensemble.name}."
          render turbo_stream: [
            turbo_stream.append("notifications", partial: "shared/notification")
          ]
          flash.discard(:alert)
        end
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

  def find_day_for_entry(contest_entry)
    @schedule.days.joins(:schedule_blocks).where(schedule_blocks: { contest_entry: contest_entry }).first
  end

  def move_entry_earlier(contest_entry)
    # Get all blocks for this entry
    entry_blocks = contest_entry.schedule_blocks.includes(:schedule_day, :performance_phase).order(:start_time)
    return false if entry_blocks.empty?
    
    first_block = entry_blocks.first
    schedule_day = first_block.schedule_day
    
    # Get the previous entry's blocks on the same day
    previous_blocks = schedule_day.schedule_blocks
      .where("start_time < ?", first_block.start_time)
      .where.not(contest_entry: contest_entry)
      .includes(:contest_entry, :performance_phase)
      .order(:start_time)
      .group_by(&:contest_entry_id)
      .values
      .last
    
    return false unless previous_blocks
    
    # Swap the time slots
    swap_block_times(entry_blocks, previous_blocks)
  end

  def move_entry_later(contest_entry)
    # Get all blocks for this entry
    entry_blocks = contest_entry.schedule_blocks.includes(:schedule_day, :performance_phase).order(:start_time)
    return false if entry_blocks.empty?
    
    last_block = entry_blocks.last
    schedule_day = last_block.schedule_day
    
    # Get the next entry's blocks on the same day
    next_blocks = schedule_day.schedule_blocks
      .where("start_time > ?", last_block.start_time)
      .where.not(contest_entry: contest_entry)
      .includes(:contest_entry, :performance_phase)
      .order(:start_time)
      .group_by(&:contest_entry_id)
      .values
      .first
    
    return false unless next_blocks
    
    # Swap the time slots
    swap_block_times(entry_blocks, next_blocks)
  end

  def swap_entry_times(entry1, entry2)
    entry1_blocks = entry1.schedule_blocks.includes(:schedule_day, :performance_phase).order(:start_time)
    entry2_blocks = entry2.schedule_blocks.includes(:schedule_day, :performance_phase).order(:start_time)
    
    return false if entry1_blocks.empty? || entry2_blocks.empty?
    
    # Make sure both entries are on the same day
    return false unless entry1_blocks.first.schedule_day == entry2_blocks.first.schedule_day
    
    swap_block_times(entry1_blocks, entry2_blocks)
  end

  def swap_block_times(blocks1, blocks2)
    return false unless blocks1.length == blocks2.length
    
    ActiveRecord::Base.transaction do
      # Store the original times from blocks1
      original_times = blocks1.map { |block| [block.start_time, block.end_time] }
      
      # Update blocks1 with times from blocks2
      blocks1.each_with_index do |block, index|
        block.update!(
          start_time: blocks2[index].start_time,
          end_time: blocks2[index].end_time
        )
      end
      
      # Update blocks2 with original times from blocks1
      blocks2.each_with_index do |block, index|
        block.update!(
          start_time: original_times[index][0],
          end_time: original_times[index][1]
        )
      end
    end
    
    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to swap schedule blocks: #{e.message}"
    false
  rescue StandardError => e
    Rails.logger.error "Unexpected error swapping schedule blocks: #{e.message}"
    false
  end
end
