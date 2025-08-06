require "test_helper"

class SchedulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @schedule = schedules(:demo_district_schedule)
    @contest = @schedule.contest
    @manager = users(:demo_manager_a)
    @director = users(:demo_director_a)
    
    # Update contest to be in the future for testing
    @contest.update!(
      contest_start: 1.week.from_now,
      contest_end: 1.week.from_now + 1.day,
      start_time: Time.parse("08:00"),
      end_time: Time.parse("17:00")
    )
    
    @entry1 = contest_entries(:contest_a_school_a_ensemble_a)
    @entry2 = contest_entries(:contest_a_school_a_ensemble_b)
  end

  test "should require manager authorization for reschedule actions" do
    sign_in_as(@director)
    
    post schedule_move_entry_up_path(@schedule, @entry2)
    assert_redirected_to root_path
    
    post schedule_move_entry_down_path(@schedule, @entry1)
    assert_redirected_to root_path
    
    post schedule_swap_entries_path(@schedule, @entry1, @entry2)
    assert_redirected_to root_path
  end

  test "should not allow rescheduling after contest start" do
    @contest.update!(contest_start: 1.hour.ago)
    sign_in_as(@manager)
    
    post schedule_move_entry_up_path(@schedule, @entry2), 
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_match "Contest has already started", @response.body
  end

  test "should move entry up in schedule" do
    sign_in_as(@manager)
    
    # Get original times for both entries
    entry1_block1 = schedule_blocks(:entry1_warmup)
    entry2_block1 = schedule_blocks(:entry2_warmup)
    entry1_original_start = entry1_block1.start_time
    entry2_original_start = entry2_block1.start_time
    
    post schedule_move_entry_up_path(@schedule, @entry2), 
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_match "moved up in schedule", @response.body
    
    # Reload blocks to get updated times
    entry1_block1.reload
    entry2_block1.reload
    
    # Entry 2 should now have entry 1's original time
    assert_equal entry1_original_start, entry2_block1.start_time
    # Entry 1 should now have entry 2's original time
    assert_equal entry2_original_start, entry1_block1.start_time
  end

  test "should move entry down in schedule" do
    sign_in_as(@manager)
    
    # Get original times for both entries
    entry1_block1 = schedule_blocks(:entry1_warmup)
    entry2_block1 = schedule_blocks(:entry2_warmup)
    entry1_original_start = entry1_block1.start_time
    entry2_original_start = entry2_block1.start_time
    
    post schedule_move_entry_down_path(@schedule, @entry1), 
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_match "moved down in schedule", @response.body
    
    # Reload blocks to get updated times
    entry1_block1.reload
    entry2_block1.reload
    
    # Entry 1 should now have entry 2's original time
    assert_equal entry2_original_start, entry1_block1.start_time
    # Entry 2 should now have entry 1's original time
    assert_equal entry1_original_start, entry2_block1.start_time
  end

  test "should swap entries" do
    sign_in_as(@manager)
    
    # Get original times for both entries
    entry1_block1 = schedule_blocks(:entry1_warmup)
    entry1_block2 = schedule_blocks(:entry1_performance)
    entry2_block1 = schedule_blocks(:entry2_warmup)
    entry2_block2 = schedule_blocks(:entry2_performance)
    
    entry1_original_start = entry1_block1.start_time
    entry1_original_end = entry1_block2.end_time
    entry2_original_start = entry2_block1.start_time
    entry2_original_end = entry2_block2.end_time
    
    post schedule_swap_entries_path(@schedule, @entry1, @entry2), 
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_match "Swapped", @response.body
    
    # Reload blocks to get updated times
    entry1_block1.reload
    entry1_block2.reload
    entry2_block1.reload
    entry2_block2.reload
    
    # Entry 1 should now have entry 2's original times
    assert_equal entry2_original_start, entry1_block1.start_time
    assert_equal entry2_original_end, entry1_block2.end_time
    
    # Entry 2 should now have entry 1's original times  
    assert_equal entry1_original_start, entry2_block1.start_time
    assert_equal entry1_original_end, entry2_block2.end_time
  end

  test "should handle invalid move operations gracefully" do
    sign_in_as(@manager)
    
    # Try to move first entry up (should fail - no previous entry)
    post schedule_move_entry_up_path(@schedule, @entry1), 
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_match "Could not move", @response.body
    
    # Try to move last entry down (should fail - no next entry)
    post schedule_move_entry_down_path(@schedule, @entry2), 
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_match "Could not move", @response.body
  end

  test "should handle invalid swap operations gracefully" do
    sign_in_as(@manager)
    
    # Try to swap with non-existent entry
    assert_raises(ActiveRecord::RecordNotFound) do
      post schedule_swap_entries_path(@schedule, @entry1, 99999), 
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
  end
end
