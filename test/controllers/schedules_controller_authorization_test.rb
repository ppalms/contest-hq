require "test_helper"

class SchedulesControllerAuthorizationTest < ActionDispatch::IntegrationTest
  CONTEST_A_START_TIME = "2026-10-01T08:00:00"
  CONTEST_A_END_TIME = "2026-10-01T18:00:00"
  CONTEST_C_START_TIME = "2026-10-01T08:00:00"
  CONTEST_C_END_TIME = "2026-10-01T18:00:00"
  AUTHORIZATION_ERROR_MESSAGE = "You must be a manager of this contest to access this area"

  def setup
    @demo_admin = create(:user, :account_admin)
    @demo_manager_a = create(:user, :manager, account: @demo_admin.account)
    @demo_manager_b = create(:user, :manager, account: @demo_admin.account)
    @demo_director_a = create(:user, :director, account: @demo_admin.account)

    @demo_contest_a = create(:contest, account: @demo_admin.account)
    @demo_schedule_a = create(:schedule, contest: @demo_contest_a, account: @demo_admin.account)
    create(:contest_manager, contest: @demo_contest_a, user: @demo_manager_a, account: @demo_admin.account)

    @demo_contest_b = create(:contest, account: @demo_admin.account)
    @demo_schedule_b = create(:schedule, contest: @demo_contest_b, account: @demo_admin.account)
    create(:contest_manager, contest: @demo_contest_b, user: @demo_manager_b, account: @demo_admin.account)

    @demo_contest_c = create(:contest, account: @demo_admin.account)
    @demo_schedule_c = create(:schedule, contest: @demo_contest_c, account: @demo_admin.account)
  end

  test "authorized manager can generate schedule for their assigned contest" do
    sign_in_as(@demo_manager_a)

    post_schedule_generation(@demo_schedule_a, CONTEST_A_START_TIME, CONTEST_A_END_TIME)

    assert_response :success
  end

  test "manager cannot generate schedule for unassigned contest in same account" do
    sign_in_as(@demo_manager_a)

    post_schedule_generation(@demo_schedule_c, CONTEST_C_START_TIME, CONTEST_C_END_TIME)

    assert_authorization_failure
  end

  test "manager cannot generate schedule for contest assigned to different manager" do
    sign_in_as(@demo_manager_b)

    post_schedule_generation(@demo_schedule_a, CONTEST_A_START_TIME, CONTEST_A_END_TIME)

    assert_authorization_failure
  end

  test "non-manager user cannot generate schedules regardless of contest" do
    sign_in_as(@demo_director_a)

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
