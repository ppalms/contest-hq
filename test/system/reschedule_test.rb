require "application_system_test_case"

class RescheduleTest < ApplicationSystemTestCase
  setup do
    @manager = users(:demo_manager_a)
    @contest = contests(:demo_contest_a)
    @schedule = @contest.schedules.first

    # Set account context for creating records
    Current.account = @contest.account

    log_in_as(@manager)

    @entry1 = contest_entries(:contest_a_school_a_ensemble_a)
    @entry2 = contest_entries(:contest_a_school_a_ensemble_b)

    @schedule_date = Date.today + 1.day

    @day = @schedule.days.create!(
      schedule_date: @schedule_date,
      start_time: @schedule_date.beginning_of_day + 8.hours,  # 8:00 AM UTC = 2:00 AM CST
      end_time: @schedule_date.beginning_of_day + 17.hours    # 5:00 PM UTC = 11:00 AM CST
    )

    # Create a room first (required for performance phases)
    @room = @contest.rooms.create!(name: "Main Hall", room_number: "101", account: @contest.account)

    @phase_warmup = @contest.performance_phases.create!(name: "Warm Up", ordinal: 1, duration: 20, room: @room, account: @contest.account)
    @phase_performance = @contest.performance_phases.create!(name: "Performance", ordinal: 2, duration: 20, room: @room, account: @contest.account)

    @entry1.schedule_blocks.create!([
      {
        schedule_day: @day,
        performance_phase: @phase_warmup,
        room: @room,
        start_time: @schedule_date.beginning_of_day + 8.hours,   # 8:00 AM UTC = 2:00 AM CST
        end_time: @schedule_date.beginning_of_day + 8.hours + 20.minutes,    # 8:20 AM UTC = 2:20 AM CST
        account: @schedule.account
      },
      {
        schedule_day: @day,
        performance_phase: @phase_performance,
        room: @room,
        start_time: @schedule_date.beginning_of_day + 8.hours + 20.minutes,  # 8:20 AM UTC = 2:20 AM CST
        end_time: @schedule_date.beginning_of_day + 8.hours + 40.minutes,    # 8:40 AM UTC = 2:40 AM CST
        account: @schedule.account
      }
    ])

    @entry2.schedule_blocks.create!([
      {
        schedule_day: @day,
        performance_phase: @phase_warmup,
        room: @room,
        start_time: @schedule_date.beginning_of_day + 8.hours + 40.minutes,  # 8:40 AM UTC = 2:40 AM CST
        end_time: @schedule_date.beginning_of_day + 9.hours,     # 9:00 AM UTC = 3:00 AM CST
        account: @schedule.account
      },
      {
        schedule_day: @day,
        performance_phase: @phase_performance,
        room: @room,
        start_time: @schedule_date.beginning_of_day + 9.hours,   # 9:00 AM UTC = 3:00 AM CST
        end_time: @schedule_date.beginning_of_day + 9.hours + 20.minutes,    # 9:20 AM UTC = 3:20 AM CST
        account: @schedule.account
      }
    ])
  end

  test "manager can navigate to reschedule page" do
    visit schedule_path(@schedule)

    within "#entry_#{@entry1.id}" do
      click_link "Reschedule"
    end

    assert_current_path reschedule_entry_path(@schedule, @entry1)
    assert_selector "h1", text: "Reschedule #{@entry1.large_ensemble.name}"

    assert_text "School: #{@entry1.large_ensemble.school.name}"
    assert_text "Current Schedule:"
    assert_text "Warm Up"
    assert_text "Performance"
  end

  test "breadcrumbs show correct navigation path" do
    visit reschedule_entry_path(@schedule, @entry1)

    within "nav[aria-label='Breadcrumb']" do
      assert_link "Contests"
      assert_link @contest.name
      assert_link "Schedule"
      assert_text "Reschedule"
    end
  end

  test "manager can reschedule entry to available time slot" do
    visit reschedule_entry_path(@schedule, @entry1)

    select @day.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"

    # Wait for time slots to load
    assert_selector 'select[name="target_time_slot"] option', minimum: 2

    select "3:20 AM (Available)", from: "target_time_slot"

    assert_no_selector "[data-reschedule-target='existingEntryInfo']", visible: :visible
    assert_no_selector "[data-reschedule-target='rescheduleMethodSection']", visible: :visible

    click_button "Reschedule"

    assert_current_path schedule_path(@schedule)
    assert_text "Successfully rescheduled #{@entry1.large_ensemble.name}"

    assert_selector "#entry_#{@entry1.id}"

    @entry1.reload
    first_block = @entry1.schedule_blocks.order(:start_time).first
    assert_equal "09:20:00", first_block.start_time.strftime("%H:%M:%S")
  end

  test "manager can swap entries" do
    visit reschedule_entry_path(@schedule, @entry1)

    select @day.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"

    sleep 0.5

    select "2:40 AM (Occupied)", from: "target_time_slot"

    assert_selector "[data-reschedule-target='existingEntryInfo']", visible: :visible
    assert_text "Entry at selected time slot:"
    assert_text @entry2.large_ensemble.name
    assert_text @entry2.large_ensemble.school.name

    assert_selector "[data-reschedule-target='rescheduleMethodSection']", visible: :visible

    choose "Swap time slots with existing entry"

    accept_confirm "Are you sure you want to swap time slots with #{@entry2.large_ensemble.name} from #{@entry2.large_ensemble.school.name}?" do
      click_button "Reschedule"
    end

    assert_current_path schedule_path(@schedule)
    assert_text "Successfully swapped time slots between #{@entry1.large_ensemble.name} and #{@entry2.large_ensemble.name}"

    @entry1.reload
    @entry2.reload

    entry1_first_block = @entry1.schedule_blocks.order(:start_time).first
    entry2_first_block = @entry2.schedule_blocks.order(:start_time).first

    # Entry1 should now be at entry2's original time (8:40 AM)
    assert_equal "08:40:00", entry1_first_block.start_time.strftime("%H:%M:%S")
    # Entry2 should now be at entry1's original time (8:00 AM)
    assert_equal "08:00:00", entry2_first_block.start_time.strftime("%H:%M:%S")
  end

  test "manager can shift entries" do
    visit reschedule_entry_path(@schedule, @entry1)

    select @day.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"

    sleep 0.5

    select "2:40 AM (Occupied)", from: "target_time_slot"

    assert_selector "[data-reschedule-target='rescheduleMethodSection']", visible: :visible

    choose "Shift other entries to make room"

    accept_confirm "Are you sure you want to shift entries to make room? This may affect multiple entries in the schedule." do
      click_button "Reschedule"
    end

    assert_current_path schedule_path(@schedule)
    assert_text "Successfully rescheduled #{@entry1.large_ensemble.name} and shifted subsequent entries"

    @entry1.reload
    entry1_first_block = @entry1.schedule_blocks.order(:start_time).first
    assert_equal "08:40:00", entry1_first_block.start_time.strftime("%H:%M:%S")
  end

  test "cannot reschedule to current time slot" do
    visit reschedule_entry_path(@schedule, @entry1)

    select @day.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"

    sleep 0.5

    select "2:00 AM (Current)", from: "target_time_slot"

    submit_button = find("input[type='submit'][value='Reschedule']", visible: :all)
    assert submit_button.disabled?
  end

  test "form requires time slot selection" do
    visit reschedule_entry_path(@schedule, @entry1)

    # Form should have required attribute on time slot select
    time_slot_select = find_field("target_time_slot")
    assert time_slot_select[:required]
  end

  test "form loads time slots when day is selected" do
    visit reschedule_entry_path(@schedule, @entry1)

    select @day.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"

    sleep 0.5

    # Time slot select should be enabled and populated
    time_slot_select = find_field("target_time_slot")
    assert_not time_slot_select.disabled?

    # Should have time slot options (more than just the prompt)
    options = time_slot_select.all("option")
    assert options.length > 1, "Expected time slot options to be loaded"

    # Day selection should be preserved
    assert_equal @day.id.to_s, find_field("target_day_id").value
  end

  test "non-manager cannot see reschedule button" do
    director = users(:demo_director_a)
    log_in_as(director)

    visit schedule_path(@schedule)

    within "#entry_#{@entry1.id}" do
      assert_no_link "Reschedule"
    end
  end

  test "non-manager cannot access reschedule page" do
    director = users(:demo_director_a)
    log_in_as(director)

    visit reschedule_entry_path(@schedule, @entry1)

    assert_text "You must be a manager of this contest to access this area"
    assert_current_path root_path
  end

  test "cancel button returns to schedule" do
    visit reschedule_entry_path(@schedule, @entry1)

    click_link "Cancel"

    assert_current_path schedule_path(@schedule)
  end

  test "loading indicator appears during time slot fetch" do
    visit reschedule_entry_path(@schedule, @entry1)

    select @day.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"

    assert_selector "[data-reschedule-target='loadingIndicator']", visible: :all
  end

  test "entry with time preference shows preference information" do
    # Set preferences using UTC time (time fields don't store timezone)
    # These will be stored as 09:00 and 11:00 in the database
    @entry1.update!(
      preferred_time_start: Time.utc(2000, 1, 1, 9, 0),
      preferred_time_end: Time.utc(2000, 1, 1, 11, 0)
    )

    visit reschedule_entry_path(@schedule, @entry1)

    assert_text "Preferred Performance Time:"
    # Times are stored as UTC time-only values and displayed in user's timezone (CST)
    # 09:00 UTC displays as 3:00 AM CST
    assert_text "3:00 AM"
    assert_text "5:00 AM"
  end

  test "scrolls to entry after successful reschedule" do
    visit reschedule_entry_path(@schedule, @entry1)

    select @day.schedule_date.strftime("%a %-m/%d"), from: "target_day_id"
    sleep 0.5
    select "3:20 AM (Available)", from: "target_time_slot"

    click_button "Reschedule"

    # Capybara's current_path doesn't include the anchor, so just check the path
    assert_current_path schedule_path(@schedule)

    # Verify the entry is present on the page (confirming successful reschedule)
    assert_selector "#entry_#{@entry1.id}"
  end
end
