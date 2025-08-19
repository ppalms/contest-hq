require "test_helper"

class SchedulesControllerAuthorizationTest < ActionDispatch::IntegrationTest
  def setup
    @demo_contest = contests(:demo_contest_a)
    @demo_schedule = schedules(:demo_district_schedule)
    @demo_manager = users(:demo_manager_a)
    @ossaa_manager = users(:ossaa_manager_a)
    @ossaa_contest = contests(:ossaa_state_orchestra)
    @ossaa_schedule = schedules(:ossaa_state_orchestra_schedule)
  end

  test "manager assigned to contest can access schedule generation" do
    # demo_manager_a is assigned to demo_contest_a via contest_managers fixture
    sign_in_as(@demo_manager)
    
    post generate_schedule_path(@demo_schedule), params: {
      start_time: "2024-10-23T08:00:00",
      end_time: "2024-10-23T18:00:00"
    }
    
    # Should succeed (not redirect to root_path)
    assert_response :success
  end

  test "manager not assigned to contest cannot access schedule generation" do
    # demo_manager_a is NOT assigned to ossaa_state_orchestra
    sign_in_as(@demo_manager)
    
    post generate_schedule_path(@ossaa_schedule), params: {
      start_time: "2024-11-19T08:00:00", 
      end_time: "2024-11-19T18:00:00"
    }
    
    # Should be redirected away due to authorization failure
    assert_redirected_to root_path
    assert_equal "You must be a manager of this contest to access this area", flash[:alert]
  end

  test "manager assigned to different contest cannot access schedule generation" do
    # ossaa_manager_a is assigned to ossaa_state_orchestra but not demo_contest_a
    sign_in_as(@ossaa_manager)
    
    post generate_schedule_path(@demo_schedule), params: {
      start_time: "2024-10-23T08:00:00",
      end_time: "2024-10-23T18:00:00"
    }
    
    # Should be redirected away due to authorization failure  
    assert_redirected_to root_path
    assert_equal "You must be a manager of this contest to access this area", flash[:alert]
  end

  test "non-manager cannot access schedule generation" do
    director = users(:demo_director_a)
    sign_in_as(director)
    
    post generate_schedule_path(@demo_schedule), params: {
      start_time: "2024-10-23T08:00:00",
      end_time: "2024-10-23T18:00:00"
    }
    
    # Should be redirected away due to authorization failure
    assert_redirected_to root_path
    assert_equal "You must be a manager of this contest to access this area", flash[:alert]
  end
end