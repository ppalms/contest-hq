require "test_helper"

class ScheduleGenerationServiceTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :account_admin)
    set_current_user(@admin)
    @contest = create(:contest, account: @admin.account)
    @schedule = create(:schedule, contest: @contest, account: @admin.account)
    create(:contest_entry, contest: @contest, account: @admin.account)
    @start_time = DateTime.parse("2026-10-01T08:00:00").utc
    @end_time = DateTime.parse("2026-10-01T18:00:00").utc
  end

  test "successfully generates schedule with valid data" do
    room = create(:room, contest: @contest, account: @contest.account)

    create(:performance_phase, contest: @contest, room: room, account: @contest.account)

    service = ScheduleGenerationService.new(@schedule, @start_time, @end_time)
    result = service.call

    assert result
    assert @schedule.days.any?
    assert ScheduleBlock.where(schedule_day: @schedule.days).any?
  end

  test "raises error when contest has already started" do
    @contest.update!(contest_start: 1.day.ago, contest_end: 1.day.from_now)

    room = create(:room, contest: @contest, account: @contest.account)

    create(:performance_phase, contest: @contest, room: room, account: @contest.account)

    service = ScheduleGenerationService.new(@schedule, @start_time, @end_time)

    error = assert_raises(ScheduleGenerationService::GenerationError) do
      service.call
    end

    assert_match(/Contest has already started/, error.message)
  end

  test "raises error when no performance phases exist" do
    service = ScheduleGenerationService.new(@schedule, @start_time, @end_time)

    error = assert_raises(ScheduleGenerationService::GenerationError) do
      service.call
    end

    assert_match(/must have at least one performance phase/, error.message)
  end

  test "raises error when performance phase has invalid duration" do
    room = create(:room, contest: @contest, account: @contest.account)
    phase = create(:performance_phase, contest: @contest, room: room, account: @contest.account)

    phase.update_column(:duration, 0)

    service = ScheduleGenerationService.new(@schedule, @start_time, @end_time)

    error = assert_raises(ScheduleGenerationService::GenerationError) do
      service.call
    end

    assert_match(/invalid duration/, error.message)
  end

  test "raises error when no contest entries exist" do
    @contest.contest_entries.destroy_all

    room = create(:room, contest: @contest, account: @contest.account)

    create(:performance_phase, contest: @contest, room: room, account: @contest.account)

    service = ScheduleGenerationService.new(@schedule, @start_time, @end_time)

    error = assert_raises(ScheduleGenerationService::GenerationError) do
      service.call
    end

    assert_match(/must have at least one entry/, error.message)
  end

  test "cleans up schedule days on failure" do
    room = create(:room, contest: @contest, account: @contest.account)
    phase = create(:performance_phase, contest: @contest, room: room, account: @contest.account)

    phase.update_column(:duration, 0)

    service = ScheduleGenerationService.new(@schedule, @start_time, @end_time)

    assert_raises(ScheduleGenerationService::GenerationError) do
      service.call
    end

    @schedule.reload
    assert_equal 0, @schedule.days.count, "Should clean up schedule days on failure"
  end

  test "creates blocks in ordinal order for multiple phases" do
    room = create(:room, contest: @contest, account: @contest.account)
    phase1 = create(:performance_phase, contest: @contest, room: room, name: "Warm-up", ordinal: 1, duration: 10, account: @contest.account)
    phase2 = create(:performance_phase, contest: @contest, room: room, name: "Performance", ordinal: 2, duration: 20, account: @contest.account)

    service = ScheduleGenerationService.new(@schedule, @start_time, @end_time)
    service.call

    first_entry = @contest.contest_entries.performance_order.first
    blocks = first_entry.schedule_blocks.order(:start_time)

    assert_equal 2, blocks.count
    assert_equal phase1.id, blocks.first.performance_phase_id
    assert_equal phase2.id, blocks.second.performance_phase_id
    assert_equal blocks.first.end_time, blocks.second.start_time
  end

  test "creates sequential blocks for multiple entries" do
    room = create(:room, contest: @contest, account: @contest.account)
    create(:performance_phase, contest: @contest, room: room, account: @contest.account)
    create(:contest_entry, contest: @contest, account: @contest.account)

    service = ScheduleGenerationService.new(@schedule, @start_time, @end_time)
    service.call

    entries = @contest.contest_entries.performance_order.limit(2)
    first_entry_blocks = entries.first.schedule_blocks.order(:start_time)
    second_entry_blocks = entries.second.schedule_blocks.order(:start_time)

    assert_equal first_entry_blocks.last.end_time, second_entry_blocks.first.start_time,
      "Second entry should start when first entry ends"
  end
end
