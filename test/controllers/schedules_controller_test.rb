require "test_helper"

class SchedulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @demo_admin = create(:user, :account_admin)
    @demo_manager_a = create(:user, :manager, account: @demo_admin.account)
    @demo_manager_b = create(:user, :manager, account: @demo_admin.account)
    @demo_director_a = create(:user, :director, account: @demo_admin.account)
    @customer_director_a = create(:user, :director)

    @demo_contest = create(:contest, account: @demo_admin.account)
    @demo_schedule = create(:schedule, contest: @demo_contest, account: @demo_admin.account)
    create(:contest_manager, contest: @demo_contest, user: @demo_manager_a, account: @demo_admin.account)

    set_current_user(@demo_director_a)
    @ensemble = create(:large_ensemble, account: @demo_admin.account)
    @entry = create(:contest_entry, contest: @demo_contest, user: @demo_director_a, large_ensemble: @ensemble, account: @demo_admin.account)
  end

  test "manager can view schedule for contest they manage" do
    sign_in_as(@demo_manager_a)

    get schedule_path(@demo_schedule)

    assert_response :success
  end

  test "manager cannot view schedule for contest they don't manage" do
    sign_in_as(@demo_manager_b)

    get schedule_path(@demo_schedule)

    assert_redirected_to root_path
    assert_equal "You do not have permission to view this schedule", flash[:alert]
  end

  test "director can view schedule for contest they have entries in" do
    sign_in_as(@demo_director_a)

    get schedule_path(@demo_schedule)

    assert_response :success
  end

  test "admin can view any schedule" do
    sign_in_as(@demo_admin)

    get schedule_path(@demo_schedule)

    assert_response :success
  end

  test "user from different account cannot view schedule" do
    sign_in_as(@customer_director_a)

    get schedule_path(@demo_schedule)

    assert_response :not_found
  end

  test "generate does not create duplicate time slots in same room" do
    sign_in_as(@demo_manager_a)

    room = create(:room, contest: @demo_contest, account: @demo_admin.account)
    create(:performance_phase, contest: @demo_contest, room: room, account: @demo_admin.account)

    post generate_schedule_path(@demo_schedule), params: {
      start_time: "2026-10-01T08:00:00",
      end_time: "2026-10-01T18:00:00"
    }, as: :turbo_stream

    assert_response :success

    @demo_schedule.reload
    blocks = ScheduleBlock.where(schedule_day: @demo_schedule.days).where(room: room)

    blocks_by_time_and_room = blocks.group_by { |b| [ b.room_id, b.start_time ] }
    blocks_by_time_and_room.each do |key, group|
      assert_equal 1, group.count, "Found duplicate blocks at #{key[1]} in room #{key[0]}"
    end
  end

  test "generate creates schedule blocks sequentially without overlaps" do
    sign_in_as(@demo_manager_a)

    room = create(:room, contest: @demo_contest, account: @demo_admin.account)
    create(:performance_phase, contest: @demo_contest, room: room, account: @demo_admin.account)

    post generate_schedule_path(@demo_schedule), params: {
      start_time: "2026-10-01T08:00:00",
      end_time: "2026-10-01T18:00:00"
    }, as: :turbo_stream

    assert_response :success

    @demo_schedule.reload
    blocks = ScheduleBlock.where(schedule_day: @demo_schedule.days).where(room: room).order(:start_time)

    blocks.each_cons(2) do |block1, block2|
      assert block1.end_time <= block2.start_time,
        "Blocks should not overlap: #{block1.start_time}-#{block1.end_time} and #{block2.start_time}-#{block2.end_time}"
    end
  end

  test "generate fails when contest has already started" do
    sign_in_as(@demo_manager_a)

    @demo_contest.update!(contest_start: 1.day.ago, contest_end: 1.day.from_now)

    room = create(:room, contest: @demo_contest, account: @demo_admin.account)
    create(:performance_phase, contest: @demo_contest, room: room, account: @demo_admin.account)

    post generate_schedule_path(@demo_schedule), params: {
      start_time: "2026-10-01T08:00:00",
      end_time: "2026-10-01T18:00:00"
    }, as: :turbo_stream

    assert_response :success
    assert_match(/Contest has already started/, flash[:alert])

    @demo_schedule.reload
    assert_equal 0, @demo_schedule.days.count, "Should not create schedule days when contest has started"
  end

  test "generate fails when contest has no performance phases" do
    sign_in_as(@demo_manager_a)

    post generate_schedule_path(@demo_schedule), params: {
      start_time: "2026-10-01T08:00:00",
      end_time: "2026-10-01T18:00:00"
    }, as: :turbo_stream

    assert_response :success
    assert_match(/must have at least one performance phase/, flash[:alert])

    @demo_schedule.reload
    assert_equal 0, @demo_schedule.days.count, "Should not create schedule days when no performance phases exist"
  end

  test "generate fails when contest has no entries" do
    sign_in_as(@demo_manager_a)

    @demo_contest.contest_entries.destroy_all

    room = create(:room, contest: @demo_contest, account: @demo_admin.account)
    create(:performance_phase, contest: @demo_contest, room: room, account: @demo_admin.account)

    post generate_schedule_path(@demo_schedule), params: {
      start_time: "2026-10-01T08:00:00",
      end_time: "2026-10-01T18:00:00"
    }, as: :turbo_stream

    assert_response :success
    assert_match(/must have at least one entry/, flash[:alert])

    @demo_schedule.reload
    assert_equal 0, @demo_schedule.days.count, "Should not create schedule days when no entries exist"
  end

  test "generate rolls back all changes when validation fails" do
    sign_in_as(@demo_manager_a)

    room = create(:room, contest: @demo_contest, account: @demo_admin.account)
    phase = create(:performance_phase, contest: @demo_contest, room: room, account: @demo_admin.account)

    phase.update_column(:duration, 0)

    post generate_schedule_path(@demo_schedule), params: {
      start_time: "2026-10-01T08:00:00",
      end_time: "2026-10-01T18:00:00"
    }, as: :turbo_stream

    assert_response :success
    assert_match(/invalid duration/, flash[:alert])

    @demo_schedule.reload
    assert_equal 0, @demo_schedule.days.count, "Should rollback schedule days on validation failure"
    assert_equal 0, ScheduleBlock.where(schedule_day: @demo_schedule.days).count, "Should rollback schedule blocks on validation failure"
  end

  test "generate uses performance phases in ordinal order" do
    sign_in_as(@demo_manager_a)

    room = create(:room, contest: @demo_contest, account: @demo_admin.account)
    phase1 = create(:performance_phase, contest: @demo_contest, room: room, account: @demo_admin.account, name: "Warm-up", ordinal: 1, duration: 10)
    phase2 = create(:performance_phase, contest: @demo_contest, room: room, account: @demo_admin.account, name: "Performance", ordinal: 2, duration: 20)

    post generate_schedule_path(@demo_schedule), params: {
      start_time: "2026-10-01T08:00:00",
      end_time: "2026-10-01T18:00:00"
    }, as: :turbo_stream

    assert_response :success

    @demo_schedule.reload
    first_entry = @demo_contest.contest_entries.performance_order.first
    blocks = first_entry.schedule_blocks.order(:start_time)

    assert_equal 2, blocks.count
    assert_equal phase1.id, blocks.first.performance_phase_id, "First block should be for phase with ordinal 1"
    assert_equal phase2.id, blocks.second.performance_phase_id, "Second block should be for phase with ordinal 2"
    assert_equal blocks.first.end_time, blocks.second.start_time, "Phases should be sequential"
  end
end
