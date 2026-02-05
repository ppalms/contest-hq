require "test_helper"

class SchedulesControllerTest < ActionDispatch::IntegrationTest
  test "manager can view schedule for contest they manage" do
    sign_in_as users(:demo_manager_a)

    get schedule_path(schedules(:demo_district_schedule))

    assert_response :success
  end

  test "manager cannot view schedule for contest they don't manage" do
    sign_in_as users(:demo_manager_b)

    get schedule_path(schedules(:demo_district_schedule))

    assert_redirected_to root_path
    assert_equal "You do not have permission to view this schedule", flash[:alert]
  end

  test "director can view schedule for contest they have entries in" do
    sign_in_as users(:demo_director_a)

    get schedule_path(schedules(:demo_district_schedule))

    assert_response :success
  end

  test "admin can view any schedule" do
    sign_in_as users(:demo_admin_a)

    get schedule_path(schedules(:demo_district_schedule))

    assert_response :success
  end

  test "user from different account cannot view schedule" do
    sign_in_as users(:customer_director_a)

    get schedule_path(schedules(:demo_district_schedule))

    assert_response :not_found
  end

  test "generate does not create duplicate time slots in same room" do
    sign_in_as users(:demo_manager_a)

    schedule = schedules(:demo_district_schedule)
    contest = schedule.contest

    room = Room.create!(
      contest: contest,
      name: "Main Hall",
      room_number: "100",
      account: contest.account
    )

    phase = PerformancePhase.create!(
      contest: contest,
      room: room,
      name: "Performance",
      ordinal: 1,
      duration: 20,
      account: contest.account
    )

    post generate_schedule_path(schedule), params: {
      start_time: "2024-10-23T08:00:00",
      end_time: "2024-10-23T18:00:00"
    }, as: :turbo_stream

    assert_response :success

    schedule.reload
    blocks = ScheduleBlock.where(schedule_day: schedule.days).where(room: room)

    blocks_by_time_and_room = blocks.group_by { |b| [ b.room_id, b.start_time ] }
    blocks_by_time_and_room.each do |key, group|
      assert_equal 1, group.count, "Found duplicate blocks at #{key[1]} in room #{key[0]}"
    end
  end

  test "generate creates schedule blocks sequentially without overlaps" do
    sign_in_as users(:demo_manager_a)

    schedule = schedules(:demo_district_schedule)
    contest = schedule.contest

    room = Room.create!(
      contest: contest,
      name: "Main Hall",
      room_number: "100",
      account: contest.account
    )

    phase = PerformancePhase.create!(
      contest: contest,
      room: room,
      name: "Performance",
      ordinal: 1,
      duration: 20,
      account: contest.account
    )

    post generate_schedule_path(schedule), params: {
      start_time: "2024-10-23T08:00:00",
      end_time: "2024-10-23T18:00:00"
    }, as: :turbo_stream

    assert_response :success

    schedule.reload
    blocks = ScheduleBlock.where(schedule_day: schedule.days).where(room: room).order(:start_time)

    blocks.each_cons(2) do |block1, block2|
      assert block1.end_time <= block2.start_time,
        "Blocks should not overlap: #{block1.start_time}-#{block1.end_time} and #{block2.start_time}-#{block2.end_time}"
    end
  end

  test "generate fails when contest has already started" do
    sign_in_as users(:demo_manager_a)

    schedule = schedules(:demo_district_schedule)
    contest = schedule.contest

    contest.update!(contest_start: 1.day.ago, contest_end: 1.day.from_now)

    room = Room.create!(
      contest: contest,
      name: "Main Hall",
      room_number: "100",
      account: contest.account
    )

    PerformancePhase.create!(
      contest: contest,
      room: room,
      name: "Performance",
      ordinal: 1,
      duration: 20,
      account: contest.account
    )

    post generate_schedule_path(schedule), params: {
      start_time: "2024-10-23T08:00:00",
      end_time: "2024-10-23T18:00:00"
    }, as: :turbo_stream

    assert_response :success
    assert_match(/Contest has already started/, flash[:alert])

    schedule.reload
    assert_equal 0, schedule.days.count, "Should not create schedule days when contest has started"
  end

  test "generate fails when contest has no performance phases" do
    sign_in_as users(:demo_manager_a)

    schedule = schedules(:demo_district_schedule)
    contest = schedule.contest

    post generate_schedule_path(schedule), params: {
      start_time: "2024-10-23T08:00:00",
      end_time: "2024-10-23T18:00:00"
    }, as: :turbo_stream

    assert_response :success
    assert_match(/must have at least one performance phase/, flash[:alert])

    schedule.reload
    assert_equal 0, schedule.days.count, "Should not create schedule days when no performance phases exist"
  end

  test "generate fails when contest has no entries" do
    sign_in_as users(:demo_manager_a)

    schedule = schedules(:demo_district_schedule)
    contest = schedule.contest

    contest.contest_entries.destroy_all

    room = Room.create!(
      contest: contest,
      name: "Main Hall",
      room_number: "100",
      account: contest.account
    )

    PerformancePhase.create!(
      contest: contest,
      room: room,
      name: "Performance",
      ordinal: 1,
      duration: 20,
      account: contest.account
    )

    post generate_schedule_path(schedule), params: {
      start_time: "2024-10-23T08:00:00",
      end_time: "2024-10-23T18:00:00"
    }, as: :turbo_stream

    assert_response :success
    assert_match(/must have at least one entry/, flash[:alert])

    schedule.reload
    assert_equal 0, schedule.days.count, "Should not create schedule days when no entries exist"
  end

  test "generate rolls back all changes when validation fails" do
    sign_in_as users(:demo_manager_a)

    schedule = schedules(:demo_district_schedule)
    contest = schedule.contest

    room = Room.create!(
      contest: contest,
      name: "Main Hall",
      room_number: "100",
      account: contest.account
    )

    phase = PerformancePhase.create!(
      contest: contest,
      room: room,
      name: "Performance",
      ordinal: 1,
      duration: 20,
      account: contest.account
    )

    phase.update_column(:duration, 0)

    post generate_schedule_path(schedule), params: {
      start_time: "2024-10-23T08:00:00",
      end_time: "2024-10-23T18:00:00"
    }, as: :turbo_stream

    assert_response :success
    assert_match(/invalid duration/, flash[:alert])

    schedule.reload
    assert_equal 0, schedule.days.count, "Should rollback schedule days on validation failure"
    assert_equal 0, ScheduleBlock.where(schedule_day: schedule.days).count, "Should rollback schedule blocks on validation failure"
  end

  test "generate uses performance phases in ordinal order" do
    sign_in_as users(:demo_manager_a)

    schedule = schedules(:demo_district_schedule)
    contest = schedule.contest

    room = Room.create!(
      contest: contest,
      name: "Main Hall",
      room_number: "100",
      account: contest.account
    )

    phase1 = PerformancePhase.create!(
      contest: contest,
      room: room,
      name: "Warm-up",
      ordinal: 1,
      duration: 10,
      account: contest.account
    )

    phase2 = PerformancePhase.create!(
      contest: contest,
      room: room,
      name: "Performance",
      ordinal: 2,
      duration: 20,
      account: contest.account
    )

    post generate_schedule_path(schedule), params: {
      start_time: "2024-10-23T08:00:00",
      end_time: "2024-10-23T18:00:00"
    }, as: :turbo_stream

    assert_response :success

    schedule.reload
    first_entry = contest.contest_entries.performance_order.first
    blocks = first_entry.schedule_blocks.order(:start_time)

    assert_equal 2, blocks.count
    assert_equal phase1.id, blocks.first.performance_phase_id, "First block should be for phase with ordinal 1"
    assert_equal phase2.id, blocks.second.performance_phase_id, "Second block should be for phase with ordinal 2"
    assert_equal blocks.first.end_time, blocks.second.start_time, "Phases should be sequential"
  end
end
