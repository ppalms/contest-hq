require "application_system_test_case"

class RescheduleMultidayTest < ApplicationSystemTestCase
  setup do
    @contest = contests(:demo_contest_a)
    @manager = users(:demo_manager_a)
    Current.account = @contest.account

    @multi_day = setup_multi_day_schedule(contest: @contest, num_days: 3)
    @schedule = @multi_day[:schedule]
    @day1 = @multi_day[:days][0]
    @day2 = @multi_day[:days][1]
    @day3 = @multi_day[:days][2]
    @room = @multi_day[:room]
    @phase = @multi_day[:phase]

    @entry1 = contest_entries(:contest_a_school_a_ensemble_a)
    @entry2 = contest_entries(:contest_a_school_a_ensemble_b)

    log_in_as(@manager)
  end

  test "reschedule entry from day 1 to available slot on day 2" do
    # Schedule at 9:00 UTC (3:00 AM CST) on day 1
    schedule_entry_at(entry: @entry1, schedule_day: @day1, phase: @phase, room: @room, start_time: "09:00")

    visit reschedule_entry_path(@schedule, @entry1)

    select @day2.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"
    sleep 1

    # Select 4:00 AM CST = 10:00 UTC on day 2
    select "4:00 AM (Available)", from: "target_time_slot"

    click_button "Reschedule"

    assert_text "Successfully"
    assert_entry_scheduled_at(@entry1, expected_day: @day2, expected_start_time: "10:00")
  end

  test "swap entry from day 1 with entry on day 2" do
    # Entry1 at 9:00 UTC on day1, Entry2 at 10:00 UTC on day2
    schedule_entry_at(entry: @entry1, schedule_day: @day1, phase: @phase, room: @room, start_time: "09:00")
    schedule_entry_at(entry: @entry2, schedule_day: @day2, phase: @phase, room: @room, start_time: "10:00")

    visit reschedule_entry_path(@schedule, @entry1)

    select @day2.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"
    sleep 1

    # Select entry2's slot (4:00 AM CST = 10:00 UTC)
    select "4:00 AM (Occupied)", from: "target_time_slot"

    choose "Swap time slots with existing entry"

    accept_confirm do
      click_button "Reschedule"
    end

    assert_text "Successfully"
    # Entry1 moves to day2 at 10:00 UTC, Entry2 moves to day1 at 09:00 UTC
    assert_entry_scheduled_at(@entry1, expected_day: @day2, expected_start_time: "10:00")
    assert_entry_scheduled_at(@entry2, expected_day: @day1, expected_start_time: "09:00")
  end

  test "shift entries on day 2 when moving entry from day 1" do
    # Entry1 at 9:00 UTC on day1, Entry2 at 10:00 UTC on day2
    schedule_entry_at(entry: @entry1, schedule_day: @day1, phase: @phase, room: @room, start_time: "09:00")
    schedule_entry_at(entry: @entry2, schedule_day: @day2, phase: @phase, room: @room, start_time: "10:00")

    visit reschedule_entry_path(@schedule, @entry1)

    select @day2.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"
    sleep 1

    # Select entry2's slot (4:00 AM CST = 10:00 UTC)
    select "4:00 AM (Occupied)", from: "target_time_slot"

    choose "Shift other entries to make room"

    accept_confirm do
      click_button "Reschedule"
    end

    assert_text "Successfully"
    # Entry1 moves to day2 at 10:00 UTC, Entry2 shifts to 10:15 UTC on day2
    assert_entry_scheduled_at(@entry1, expected_day: @day2, expected_start_time: "10:00")
    assert_entry_scheduled_at(@entry2, expected_day: @day2, expected_start_time: "10:15")
  end

  test "move entry across multiple days (day 1 to day 3)" do
    # Schedule at 9:00 UTC (3:00 AM CST) on day 1
    schedule_entry_at(entry: @entry1, schedule_day: @day1, phase: @phase, room: @room, start_time: "09:00")

    visit reschedule_entry_path(@schedule, @entry1)

    select @day3.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"
    sleep 1

    # Select 8:00 AM CST = 14:00 UTC on day 3
    select "8:00 AM (Available)", from: "target_time_slot"

    click_button "Reschedule"

    assert_text "Successfully"
    assert_entry_scheduled_at(@entry1, expected_day: @day3, expected_start_time: "14:00")
  end
end
