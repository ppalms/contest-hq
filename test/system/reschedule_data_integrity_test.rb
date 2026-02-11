require "application_system_test_case"

class RescheduleDataIntegrityTest < ApplicationSystemTestCase
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

  test "preserve room assignment when rescheduling" do
    # Schedule at 9:00 UTC (3:00 AM CST) on day 1
    schedule_entry_at(entry: @entry1, schedule_day: @day1, phase: @phase, room: @room, start_time: "09:00")

    visit reschedule_entry_path(@schedule, @entry1)

    select @day2.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"
    # Wait for time slots to load
    assert_selector 'select[name="target_time_slot"] option', minimum: 2

    # Select 4:00 AM CST = 10:00 UTC on day 2
    select "4:00 AM (Available)", from: "target_time_slot"

    click_button "Reschedule"

    assert_text "Successfully"

    @entry1.reload
    block = @entry1.schedule_blocks.first
    assert_equal @room.id, block.room_id, "Room assignment should be preserved"
  end

  test "preserve performance phase when rescheduling" do
    # Schedule at 9:00 UTC (3:00 AM CST) on day 1
    schedule_entry_at(entry: @entry1, schedule_day: @day1, phase: @phase, room: @room, start_time: "09:00")

    visit reschedule_entry_path(@schedule, @entry1)

    select @day2.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"
    # Wait for time slots to load
    assert_selector 'select[name="target_time_slot"] option', minimum: 2

    # Select 4:00 AM CST = 10:00 UTC on day 2
    select "4:00 AM (Available)", from: "target_time_slot"

    click_button "Reschedule"

    assert_text "Successfully"

    @entry1.reload
    block = @entry1.schedule_blocks.first
    assert_equal @phase.id, block.performance_phase_id, "Performance phase should be preserved"
  end

  test "maintain phase order when shifting entries" do
    # Use the default phase which has 15-minute duration
    # Entry1 at 9:00 UTC (3:00 AM CST), Entry2 at 10:00 UTC (4:00 AM CST)
    schedule_entry_at(entry: @entry1, schedule_day: @day1, phase: @phase, room: @room, start_time: "09:00")
    schedule_entry_at(entry: @entry2, schedule_day: @day1, phase: @phase, room: @room, start_time: "10:00")

    visit reschedule_entry_path(@schedule, @entry1)

    select @day1.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"
    # Wait for time slots to load
    assert_selector 'select[name="target_time_slot"] option', minimum: 2

    # Select entry2's slot (4:00 AM CST = 10:00 UTC)
    select "4:00 AM (Occupied)", from: "target_time_slot"

    choose "Shift other entries to make room"

    accept_confirm do
      click_button "Reschedule"
    end

    assert_text "Successfully"

    @entry1.reload
    @entry2.reload

    # Both entries should still use the same phase after shift
    assert_equal @phase.id, @entry1.schedule_blocks.first.performance_phase_id
    assert_equal @phase.id, @entry2.schedule_blocks.first.performance_phase_id
  end
end
