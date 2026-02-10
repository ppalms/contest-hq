require "application_system_test_case"

class RescheduleEdgeCasesTest < ApplicationSystemTestCase
  setup do
    @contest = contests(:demo_contest_a)
    @manager = users(:demo_manager_a)
    Current.account = @contest.account

    @multi_day = setup_multi_day_schedule(contest: @contest, num_days: 2)
    @schedule = @multi_day[:schedule]
    @day1 = @multi_day[:days][0]
    @day2 = @multi_day[:days][1]
    @room = @multi_day[:room]
    @phase = @multi_day[:phase]

    @entry1 = contest_entries(:contest_a_school_a_ensemble_a)

    log_in_as(@manager)
  end

  test "prevent rescheduling to same time slot" do
    schedule_entry_at(entry: @entry1, schedule_day: @day1, phase: @phase, room: @room, start_time: "09:00 AM")

    visit reschedule_entry_path(@schedule, @entry1)

    select @day1.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"
    sleep 1

    select "3:00 AM (Current)", from: "target_time_slot"

    # Submit button should be disabled when current slot is selected
    submit_button = find("input[type='submit'][value='Reschedule']", visible: :all)
    assert submit_button.disabled?

    assert_entry_scheduled_at(@entry1, expected_day: @day1, expected_start_time: "09:00")
  end

  test "handle missing schedule day selection" do
    schedule_entry_at(entry: @entry1, schedule_day: @day1, phase: @phase, room: @room, start_time: "09:00 AM")

    visit reschedule_entry_path(@schedule, @entry1)

    # Form has HTML5 required validation - browser prevents submission
    # Just verify the form has required fields
    day_select = find_field("target_day_id")
    time_select = find_field("target_time_slot")

    assert day_select[:required]
    assert time_select[:required]

    assert_entry_scheduled_at(@entry1, expected_day: @day1, expected_start_time: "09:00")
  end

  test "handle missing time slot selection" do
    schedule_entry_at(entry: @entry1, schedule_day: @day1, phase: @phase, room: @room, start_time: "09:00 AM")

    visit reschedule_entry_path(@schedule, @entry1)

    select @day2.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"
    sleep 1

    # Form has HTML5 required validation - browser prevents submission
    # Verify time slot select has required attribute
    time_select = find_field("target_time_slot")
    assert time_select[:required]

    assert_entry_scheduled_at(@entry1, expected_day: @day1, expected_start_time: "09:00")
  end
end
