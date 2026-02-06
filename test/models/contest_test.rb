require "test_helper"

class ContestTest < ActiveSupport::TestCase
  setup do
    @contest = contests(:demo_contest_a)
    set_current_user(users(:demo_admin_a))
  end

  test "setup_complete? returns false when no rooms or phases" do
    # Create a new contest without any associations
    contest = Contest.create!(
      name: "Test Contest",
      contest_start: 1.month.from_now,
      contest_end: 1.month.from_now + 1.day,
      account: accounts(:demo),
      season: seasons(:demo_2024)
    )

    assert_not contest.setup_complete?
  end

  test "setup_complete? returns false when setup is not complete" do
    # For the existing contest, ensure it's not complete by default
    # (we'll assume the fixtures don't have full setup)

    # If it has rooms and phases, remove them for this test
    @contest.performance_phases.destroy_all
    @contest.rooms.destroy_all

    assert_not @contest.setup_complete?
  end

  test "setup_complete? returns true when both rooms and phases exist" do
    # Create room and performance phase for this test
    room = @contest.rooms.create!(name: "Test Room", room_number: "101")
    @contest.performance_phases.create!(
      name: "Performance",
      duration: 15,
      ordinal: 1,
      room: room
    )

    assert @contest.setup_complete?
  end

  test "setup_status returns 'Needs Setup' when setup not complete" do
    # Clear rooms and phases
    @contest.rooms.destroy_all
    @contest.performance_phases.destroy_all

    assert_equal "Needs Setup", @contest.setup_status
  end

  test "setup_status returns 'Ready to Schedule' when setup complete but no schedule days" do
    # Ensure setup is complete
    room = @contest.rooms.create!(name: "Test Room", room_number: "101")
    @contest.performance_phases.create!(
      name: "Performance",
      duration: 15,
      ordinal: 1,
      room: room
    )

    # Ensure no schedule days
    @contest.schedules.each { |schedule| schedule.schedule_days.destroy_all }

    assert_equal "Ready to Schedule", @contest.setup_status
  end

  test "setup_status returns 'Scheduled' when schedule days exist" do
    # Ensure setup is complete
    room = @contest.rooms.create!(name: "Test Room", room_number: "101")
    @contest.performance_phases.create!(
      name: "Performance",
      duration: 15,
      ordinal: 1,
      room: room
    )

    # Create a schedule with days
    schedule = @contest.schedules.first || @contest.create_schedule!
    schedule.schedule_days.create!(
      schedule_date: @contest.contest_start.to_date,
      start_time: @contest.contest_start.beginning_of_day + 8.hours,
      end_time: @contest.contest_start.beginning_of_day + 17.hours
    )

    assert_equal "Scheduled", @contest.setup_status
  end

  test "has default required_prescribed_count of 1" do
    contest = Contest.new(
      name: "Test Contest",
      contest_start: 1.month.from_now,
      contest_end: 1.month.from_now + 1.day,
      account: accounts(:demo),
      season: seasons(:demo_2024)
    )

    assert_equal 1, contest.required_prescribed_count
  end

  test "has default required_custom_count of 2" do
    contest = Contest.new(
      name: "Test Contest",
      contest_start: 1.month.from_now,
      contest_end: 1.month.from_now + 1.day,
      account: accounts(:demo),
      season: seasons(:demo_2024)
    )

    assert_equal 2, contest.required_custom_count
  end

  test "validates required_prescribed_count is non-negative" do
    @contest.required_prescribed_count = -1
    assert_not @contest.valid?
    assert_includes @contest.errors[:required_prescribed_count], "must be greater than or equal to 0"
  end

  test "validates required_custom_count is non-negative" do
    @contest.required_custom_count = -1
    assert_not @contest.valid?
    assert_includes @contest.errors[:required_custom_count], "must be greater than or equal to 0"
  end

  test "total_required_music_count returns sum of prescribed and custom" do
    @contest.required_prescribed_count = 2
    @contest.required_custom_count = 3
    assert_equal 5, @contest.total_required_music_count
  end

  test "allows zero prescribed music requirement" do
    @contest.required_prescribed_count = 0
    @contest.required_custom_count = 3
    assert @contest.valid?
    assert_equal 3, @contest.total_required_music_count
  end

  test "allows zero custom music requirement" do
    @contest.required_prescribed_count = 3
    @contest.required_custom_count = 0
    assert @contest.valid?
    assert_equal 3, @contest.total_required_music_count
  end
end
