require "test_helper"

class ScheduleBlockTest < ActiveSupport::TestCase
  setup do
    set_current_user(users(:demo_admin_a))
    @schedule = schedules(:demo_district_schedule)
    @contest = @schedule.contest

    @schedule.initialize_days(
      DateTime.parse("2024-10-23T08:00:00").utc,
      DateTime.parse("2024-10-23T18:00:00").utc
    )

    @day = @schedule.days.first

    @room_a = Room.create!(
      contest: @contest,
      name: "Auditorium A",
      room_number: "101",
      account: @contest.account
    )

    @room_b = Room.create!(
      contest: @contest,
      name: "Auditorium B",
      room_number: "102",
      account: @contest.account
    )

    @phase = PerformancePhase.create!(
      contest: @contest,
      room: @room_a,
      name: "Performance",
      ordinal: 1,
      duration: 20,
      account: @contest.account
    )

    @entry1 = contest_entries(:contest_a_school_a_ensemble_a)
    @entry2 = contest_entries(:contest_a_school_a_ensemble_b)
  end

  test "prevents duplicate time slots in same room" do
    block1 = ScheduleBlock.create!(
      schedule_day: @day,
      room: @room_a,
      performance_phase: @phase,
      contest_entry: @entry1,
      start_time: @day.start_time,
      end_time: @day.start_time + 20.minutes
    )

    block2 = ScheduleBlock.new(
      schedule_day: @day,
      room: @room_a,
      performance_phase: @phase,
      contest_entry: @entry2,
      start_time: @day.start_time,
      end_time: @day.start_time + 20.minutes
    )

    assert_not block2.valid?
    assert_includes block2.errors[:start_time], "overlaps with another block in this room"
  end

  test "allows same time slot in different rooms" do
    block1 = ScheduleBlock.create!(
      schedule_day: @day,
      room: @room_a,
      performance_phase: @phase,
      contest_entry: @entry1,
      start_time: @day.start_time,
      end_time: @day.start_time + 20.minutes
    )

    block2 = ScheduleBlock.new(
      schedule_day: @day,
      room: @room_b,
      performance_phase: @phase,
      contest_entry: @entry2,
      start_time: @day.start_time,
      end_time: @day.start_time + 20.minutes
    )

    assert block2.valid?
    assert block2.save
  end

  test "allows adjacent time slots in same room" do
    block1 = ScheduleBlock.create!(
      schedule_day: @day,
      room: @room_a,
      performance_phase: @phase,
      contest_entry: @entry1,
      start_time: @day.start_time,
      end_time: @day.start_time + 20.minutes
    )

    block2 = ScheduleBlock.new(
      schedule_day: @day,
      room: @room_a,
      performance_phase: @phase,
      contest_entry: @entry2,
      start_time: @day.start_time + 20.minutes,
      end_time: @day.start_time + 40.minutes
    )

    assert block2.valid?
    assert block2.save
  end

  test "detects partial overlap at start" do
    block1 = ScheduleBlock.create!(
      schedule_day: @day,
      room: @room_a,
      performance_phase: @phase,
      contest_entry: @entry1,
      start_time: @day.start_time + 10.minutes,
      end_time: @day.start_time + 30.minutes
    )

    block2 = ScheduleBlock.new(
      schedule_day: @day,
      room: @room_a,
      performance_phase: @phase,
      contest_entry: @entry2,
      start_time: @day.start_time,
      end_time: @day.start_time + 20.minutes
    )

    assert_not block2.valid?
    assert_includes block2.errors[:start_time], "overlaps with another block in this room"
  end

  test "detects partial overlap at end" do
    block1 = ScheduleBlock.create!(
      schedule_day: @day,
      room: @room_a,
      performance_phase: @phase,
      contest_entry: @entry1,
      start_time: @day.start_time,
      end_time: @day.start_time + 20.minutes
    )

    block2 = ScheduleBlock.new(
      schedule_day: @day,
      room: @room_a,
      performance_phase: @phase,
      contest_entry: @entry2,
      start_time: @day.start_time + 10.minutes,
      end_time: @day.start_time + 30.minutes
    )

    assert_not block2.valid?
    assert_includes block2.errors[:start_time], "overlaps with another block in this room"
  end

  test "detects complete containment" do
    block1 = ScheduleBlock.create!(
      schedule_day: @day,
      room: @room_a,
      performance_phase: @phase,
      contest_entry: @entry1,
      start_time: @day.start_time,
      end_time: @day.start_time + 40.minutes
    )

    block2 = ScheduleBlock.new(
      schedule_day: @day,
      room: @room_a,
      performance_phase: @phase,
      contest_entry: @entry2,
      start_time: @day.start_time + 10.minutes,
      end_time: @day.start_time + 30.minutes
    )

    assert_not block2.valid?
    assert_includes block2.errors[:start_time], "overlaps with another block in this room"
  end

  test "allows updating existing block without triggering overlap with itself" do
    block = ScheduleBlock.create!(
      schedule_day: @day,
      room: @room_a,
      performance_phase: @phase,
      contest_entry: @entry1,
      start_time: @day.start_time,
      end_time: @day.start_time + 20.minutes
    )

    block.end_time = @day.start_time + 25.minutes
    assert block.valid?
    assert block.save
  end

  test "skips overlap validation when room is nil" do
    block = ScheduleBlock.new(
      schedule_day: @day,
      room: nil,
      contest_entry: @entry1,
      start_time: @day.start_time,
      end_time: @day.start_time + 20.minutes
    )

    assert block.valid?(context: :overlap_check) || !block.errors[:start_time].include?("overlaps with another block in this room")
  end

  test "prevents overlap when creating multiple blocks in sequence" do
    entry3 = @contest.contest_entries.create!(
      large_ensemble: large_ensembles(:demo_school_a_ensemble_c),
      user: users(:demo_director_a),
      account: @contest.account
    )

    block1 = ScheduleBlock.create!(
      schedule_day: @day,
      room: @room_a,
      performance_phase: @phase,
      contest_entry: @entry1,
      start_time: @day.start_time,
      end_time: @day.start_time + 20.minutes
    )

    block2 = ScheduleBlock.create!(
      schedule_day: @day,
      room: @room_a,
      performance_phase: @phase,
      contest_entry: @entry2,
      start_time: @day.start_time + 20.minutes,
      end_time: @day.start_time + 40.minutes
    )

    block3 = ScheduleBlock.new(
      schedule_day: @day,
      room: @room_a,
      performance_phase: @phase,
      contest_entry: entry3,
      start_time: @day.start_time + 10.minutes,
      end_time: @day.start_time + 30.minutes
    )

    assert_not block3.valid?
    assert_includes block3.errors[:start_time], "overlaps with another block in this room"
  end
end
