require "application_system_test_case"

class RescheduleBoundariesTest < ApplicationSystemTestCase
  setup do
    @contest = contests(:demo_contest_a)
    @manager = users(:demo_manager_a)
    Current.account = @contest.account

    @multi_day = setup_multi_day_schedule(contest: @contest, num_days: 2)
    @schedule = @multi_day[:schedule]
    @day1 = @multi_day[:days][0]
    @day2 = @multi_day[:days][1]
    @room = @multi_day[:room]

    @phase = PerformancePhase.create!(
      contest: @contest,
      account: @contest.account,
      name: "Long Performance",
      duration: 30,
      room: @room,
      ordinal: 2
    )

    @entry1 = contest_entries(:contest_a_school_a_ensemble_a)
    @entry2 = contest_entries(:contest_a_school_a_ensemble_b)

    log_in_as(@manager)
  end

  test "allow rescheduling entry that extends past day end time" do
    # Schedule at 9:00 AM UTC (3:00 AM CST)
    schedule_entry_at(entry: @entry1, schedule_day: @day1, phase: @phase, room: @room, start_time: "09:00", duration_minutes: 30)

    visit reschedule_entry_path(@schedule, @entry1)

    select @day1.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"
    sleep 1

    # Schedule ends at 17:00 UTC (11:00 AM CST), so 10:30 AM CST (16:30 UTC) would extend past
    select "10:30 AM (Available)", from: "target_time_slot"

    click_button "Reschedule"

    assert_text "Successfully"
    # 10:30 AM CST = 16:30 UTC, with 30 min duration ends at 17:00 UTC
    assert_entry_scheduled_at(@entry1, expected_day: @day1, expected_start_time: "16:30", expected_duration: 30)

    @entry1.reload
    block = @entry1.schedule_blocks.first
    day_end = @day1.end_time
    assert block.end_time >= day_end, "Entry should extend to or past day end time"
  end

  test "allow shift that pushes entries past day end time" do
    # Entry1 at 9:00 AM UTC (3:00 AM CST), Entry2 at 16:30 UTC (10:30 AM CST)
    schedule_entry_at(entry: @entry1, schedule_day: @day1, phase: @phase, room: @room, start_time: "09:00", duration_minutes: 30)
    schedule_entry_at(entry: @entry2, schedule_day: @day1, phase: @phase, room: @room, start_time: "16:30", duration_minutes: 30)

    visit reschedule_entry_path(@schedule, @entry1)

    select @day1.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"
    sleep 1

    # Select entry2's time slot (10:30 AM CST = 16:30 UTC)
    select "10:30 AM (Occupied)", from: "target_time_slot"

    choose "Shift other entries to make room"

    accept_confirm do
      click_button "Reschedule"
    end

    assert_text "Successfully"
    # Entry1 moves to 16:30 UTC, Entry2 shifts to 17:00 UTC (past day end)
    assert_entry_scheduled_at(@entry1, expected_day: @day1, expected_start_time: "16:30")
    assert_entry_scheduled_at(@entry2, expected_day: @day1, expected_start_time: "17:00")
  end

  test "reschedule to last possible slot on day" do
    # Schedule at 9:00 AM UTC (3:00 AM CST)
    schedule_entry_at(entry: @entry1, schedule_day: @day1, phase: @phase, room: @room, start_time: "09:00", duration_minutes: 30)

    visit reschedule_entry_path(@schedule, @entry1)

    select @day1.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"
    sleep 1

    # Last slot that fits 30 min before 17:00 UTC (11:00 AM CST) is 16:30 UTC (10:30 AM CST)
    select "10:30 AM (Available)", from: "target_time_slot"

    click_button "Reschedule"

    assert_text "Successfully"
    assert_entry_scheduled_at(@entry1, expected_day: @day1, expected_start_time: "16:30", expected_duration: 30)
  end

  test "reschedule to first slot on day" do
    # Schedule at 14:00 UTC (8:00 AM CST)
    schedule_entry_at(entry: @entry1, schedule_day: @day1, phase: @phase, room: @room, start_time: "14:00", duration_minutes: 30)

    visit reschedule_entry_path(@schedule, @entry1)

    select @day1.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"
    sleep 1

    # First slot is 9:00 AM UTC (3:00 AM CST)
    select "3:00 AM (Available)", from: "target_time_slot"

    click_button "Reschedule"

    assert_text "Successfully"
    assert_entry_scheduled_at(@entry1, expected_day: @day1, expected_start_time: "09:00", expected_duration: 30)
  end
end
