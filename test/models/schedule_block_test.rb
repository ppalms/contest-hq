require "test_helper"

class ScheduleBlockTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :account_admin)
    set_current_user(@admin)
    @contest = create(:contest, account: @admin.account)
    @schedule = create(:schedule, account: @admin.account, contest: @contest)

    @schedule.initialize_days(
      DateTime.parse("2024-10-23T08:00:00").utc,
      DateTime.parse("2024-10-23T18:00:00").utc
    )

    @day = @schedule.days.first

    @room_a = create(:room, contest: @contest, account: @admin.account, name: "Auditorium A", room_number: "101")
    @room_b = create(:room, contest: @contest, account: @admin.account, name: "Auditorium B", room_number: "102")

    @phase = create(:performance_phase, contest: @contest, room: @room_a, account: @admin.account, name: "Performance", ordinal: 1, duration: 20)

    @entry1 = create(:contest_entry, account: @admin.account, user: @admin)
    @entry2 = create(:contest_entry, account: @admin.account, user: @admin)
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
    entry3 = create(:contest_entry, account: @admin.account, user: @admin)

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
