require "application_system_test_case"

class RescheduleComplexTest < ApplicationSystemTestCase
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
    @entry2 = contest_entries(:contest_a_school_a_ensemble_b)

    log_in_as(@manager)
  end

  test "cascading shift with multiple entries" do
    # Entry1 at 9:00 UTC (3:00 AM CST), Entry2 at 10:00 UTC (4:00 AM CST)
    schedule_entry_at(entry: @entry1, schedule_day: @day1, phase: @phase, room: @room, start_time: "09:00")
    schedule_entry_at(entry: @entry2, schedule_day: @day1, phase: @phase, room: @room, start_time: "10:00")

    visit reschedule_entry_path(@schedule, @entry1)

    select @day1.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"
    sleep 1

    # Select entry2's slot (4:00 AM CST = 10:00 UTC)
    select "4:00 AM (Occupied)", from: "target_time_slot"

    choose "Shift other entries to make room"

    accept_confirm do
      click_button "Reschedule"
    end

    assert_text "Successfully"
    # Entry1 moves to 10:00 UTC, Entry2 shifts to 10:15 UTC (15 min phase duration)
    assert_entry_scheduled_at(@entry1, expected_day: @day1, expected_start_time: "10:00")
    assert_entry_scheduled_at(@entry2, expected_day: @day1, expected_start_time: "10:15")
  end

  test "shift entries across day boundary" do
    # Entry1 at 9:00 UTC (3:00 AM CST), Entry2 at 16:45 UTC (10:45 AM CST)
    schedule_entry_at(entry: @entry1, schedule_day: @day1, phase: @phase, room: @room, start_time: "09:00")
    schedule_entry_at(entry: @entry2, schedule_day: @day1, phase: @phase, room: @room, start_time: "16:45")

    visit reschedule_entry_path(@schedule, @entry1)

    select @day1.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"
    sleep 1

    # Select entry2's slot (10:45 AM CST = 16:45 UTC)
    select "10:45 AM (Occupied)", from: "target_time_slot"

    choose "Shift other entries to make room"

    accept_confirm do
      click_button "Reschedule"
    end

    assert_text "Successfully"
    # Entry1 moves to 16:45 UTC, Entry2 shifts to 17:00 UTC (past day end at 17:00)
    assert_entry_scheduled_at(@entry1, expected_day: @day1, expected_start_time: "16:45")
    assert_entry_scheduled_at(@entry2, expected_day: @day1, expected_start_time: "17:00")
  end
end
