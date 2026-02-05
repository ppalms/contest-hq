class ScheduleGenerationService
  class GenerationError < StandardError; end

  def initialize(schedule, start_time, end_time)
    @schedule = schedule
    @contest = schedule.contest
    @start_time = start_time
    @end_time = end_time
    @errors = []
  end

  def call
    validate_prerequisites!
    generate_schedule!
    true
  rescue GenerationError => e
    cleanup_failed_generation
    raise e
  end

  private

  def validate_prerequisites!
    validate_contest_not_started
    validate_performance_phases_exist
    validate_performance_phases_valid
    validate_contest_entries_exist

    raise GenerationError, @errors.join(". ") if @errors.any?
  end

  def validate_contest_not_started
    if @contest.contest_start < DateTime.now
      @errors << "Contest has already started. Cannot generate schedule"
    end
  end

  def validate_performance_phases_exist
    if @contest.performance_phases.empty?
      @errors << "Contest must have at least one performance phase"
    end
  end

  def validate_performance_phases_valid
    @contest.performance_phases.each do |phase|
      if phase.room.nil?
        @errors << "Performance phase '#{phase.name}' has no room assigned"
      end

      if phase.duration.nil? || phase.duration <= 0
        @errors << "Performance phase '#{phase.name}' has invalid duration"
      end
    end
  end

  def validate_contest_entries_exist
    if @contest.contest_entries.empty?
      @errors << "Contest must have at least one entry to generate a schedule"
    end
  end

  def generate_schedule!
    ActiveRecord::Base.transaction do
      cleanup_existing_schedule
      initialize_schedule_days
      generate_schedule_blocks
    end
  end

  def cleanup_existing_schedule
    days_count = @schedule.schedule_days.count
    blocks_count = ScheduleBlock.where(schedule_day: @schedule.schedule_days).count

    Rails.logger.info "Cleaning up existing schedule: #{days_count} days, #{blocks_count} blocks"

    @schedule.schedule_days.destroy_all
    @schedule.reload

    remaining_days = @schedule.schedule_days.count
    remaining_blocks = ScheduleBlock.joins(:schedule_day).where(schedule_days: { schedule_id: @schedule.id }).count

    Rails.logger.info "After cleanup: #{remaining_days} days, #{remaining_blocks} blocks remaining"
  end

  def initialize_schedule_days
    @schedule.initialize_days(@start_time, @end_time)

    if @schedule.days.empty?
      raise GenerationError, "Failed to create schedule days. Check that contest dates are valid"
    end
  end

  def generate_schedule_blocks
    entries = @contest.contest_entries.performance_order
    current_day = @schedule.days.first

    Rails.logger.info "Generating schedule for #{entries.count} entries with #{@contest.performance_phases.count} phases"

    entries.each_with_index do |entry, index|
      increment_day = index > 0 && index % 20 == 0

      if increment_day
        next_day = @schedule.days.find_by(schedule_date: current_day.schedule_date + 1)
        current_day = next_day if next_day.present?
      end

      start_time = calculate_entry_start_time(entries, index, increment_day, current_day)
      create_blocks_for_entry(entry, current_day, start_time)
    end
  end

  def calculate_entry_start_time(entries, index, increment_day, current_day)
    if index == 0 || increment_day
      current_day.start_time
    else
      previous_entry = entries[index - 1]
      end_time = previous_entry.schedule_blocks.by_start_time.last&.end_time

      if end_time.nil?
        raise GenerationError, "Failed to get end time from previous entry (index #{index - 1}). Previous entry may have failed to save blocks"
      end

      end_time
    end
  end

  def create_blocks_for_entry(entry, current_day, start_time)
    phase_start = start_time

    @contest.performance_phases.by_ordinal.each do |phase|
      block = ScheduleBlock.new(
        schedule_day: current_day,
        room: phase.room,
        contest_entry: entry,
        performance_phase: phase,
        start_time: phase_start,
        end_time: phase_start + phase.duration.minutes
      )

      unless block.save
        Rails.logger.error "Failed to save block: entry=#{entry.large_ensemble.name}, phase=#{phase.name}, room=#{phase.room.name}, start=#{phase_start}, end=#{phase_start + phase.duration.minutes}"
        Rails.logger.error "Existing blocks in room #{phase.room.name} on day #{current_day.schedule_date}:"
        ScheduleBlock.where(schedule_day: current_day, room: phase.room).each do |existing|
          Rails.logger.error "  - #{existing.contest_entry.large_ensemble.name}: #{existing.start_time} to #{existing.end_time}"
        end

        error_msg = "Failed to save schedule block for entry '#{entry.large_ensemble.name}', phase '#{phase.name}': #{block.errors.full_messages.join(', ')}"
        Rails.logger.error error_msg
        raise GenerationError, error_msg
      end

      phase_start = block.end_time
    end
  end

  def cleanup_failed_generation
    @schedule.schedule_days.destroy_all
  end
end
