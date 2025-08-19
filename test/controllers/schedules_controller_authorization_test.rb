require "test_helper"

class SchedulesControllerAuthorizationTest < ActionDispatch::IntegrationTest
  CONTEST_A_START_TIME = "2024-10-23T08:00:00"
  CONTEST_A_END_TIME = "2024-10-23T18:00:00"
  CONTEST_C_START_TIME = "2025-02-18T08:00:00"
  CONTEST_C_END_TIME = "2025-02-18T18:00:00"
  AUTHORIZATION_ERROR_MESSAGE = "You must be a manager of this contest to access this area"

  def setup
    @demo_contest_a = contests(:demo_contest_a)
    @demo_schedule_a = schedules(:demo_district_schedule)
    @demo_manager_a = users(:demo_manager_a)

    @demo_contest_b = contests(:demo_contest_b)
    @demo_schedule_b = schedules(:demo_regional_schedule)
    @demo_manager_b = users(:demo_manager_b)

    @demo_contest_c = contests(:demo_contest_c)
    @demo_schedule_c = schedules(:demo_state_schedule)
  end

  # Positive authorization test
  test "authorized manager can generate schedule for their assigned contest" do
    # demo_manager_a is assigned to demo_contest_a via contest_managers fixture
    sign_in_as(@demo_manager_a)

    post_schedule_generation(@demo_schedule_a, CONTEST_A_START_TIME, CONTEST_A_END_TIME)

    # Should succeed (not redirect to root_path)
    assert_response :success
  end

  # Negative authorization tests - within same account
  test "manager cannot generate schedule for unassigned contest in same account" do
    # demo_manager_a is assigned to demo_contest_a but NOT to demo_contest_c
    sign_in_as(@demo_manager_a)

    post_schedule_generation(@demo_schedule_c, CONTEST_C_START_TIME, CONTEST_C_END_TIME)

    assert_authorization_failure
  end

  test "manager cannot generate schedule for contest assigned to different manager" do
    # demo_manager_b is assigned to demo_contest_b but not demo_contest_a
    sign_in_as(@demo_manager_b)

    post_schedule_generation(@demo_schedule_a, CONTEST_A_START_TIME, CONTEST_A_END_TIME)

    assert_authorization_failure
  end

  test "non-manager user cannot generate schedules regardless of contest" do
    director = users(:demo_director_a)
    sign_in_as(director)

    post_schedule_generation(@demo_schedule_a, CONTEST_A_START_TIME, CONTEST_A_END_TIME)

    assert_authorization_failure
  end

  private

  def post_schedule_generation(schedule, start_time, end_time)
    post generate_schedule_path(schedule), params: {
      start_time: start_time,
      end_time: end_time
    }, as: :turbo_stream
  end

  def assert_authorization_failure
    assert_redirected_to root_path
    assert_equal AUTHORIZATION_ERROR_MESSAGE, flash[:alert]
  end
end
