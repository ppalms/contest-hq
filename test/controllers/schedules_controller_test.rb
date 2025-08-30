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
end
