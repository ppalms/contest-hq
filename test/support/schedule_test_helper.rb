module ScheduleTestHelper
  def setup_multi_day_schedule(contest:, num_days: 2, start_date: Date.today)
    schedule = contest.schedules.first || Schedule.create!(
      contest: contest,
      account: contest.account
    )

    room = contest.rooms.first || Room.create!(
      account: contest.account,
      contest: contest,
      name: "Test Room",
      room_number: "TR#{rand(1000)}"
    )

    days = []
    num_days.times do |i|
      date = start_date + i.days
      day = ScheduleDay.create!(
        schedule: schedule,
        account: contest.account,
        schedule_date: date,
        start_time: date.beginning_of_day + 9.hours,   # 9:00 AM UTC = 3:00 AM CST
        end_time: date.beginning_of_day + 17.hours     # 5:00 PM UTC = 11:00 AM CST
      )
      days << day
    end

    phase = contest.performance_phases.first || PerformancePhase.create!(
      contest: contest,
      account: contest.account,
      name: "Performance",
      duration: 15,
      room: room,
      ordinal: 1
    )

    { schedule: schedule, days: days, room: room, phase: phase }
  end

  def schedule_entry_at(entry:, schedule_day:, phase:, room:, start_time:, duration_minutes: nil)
    duration_minutes ||= phase.duration

    date = schedule_day.schedule_date

    # Parse start_time - if it's in "HH:MM" format, treat as UTC hours
    # If it's in "HH:MM AM/PM" format, parse as time string
    if start_time.match?(/^\d{1,2}:\d{2}$/)
      # Format like "09:00" - treat as UTC hours
      hours, minutes = start_time.split(":").map(&:to_i)
      start_time_obj = date.beginning_of_day + hours.hours + minutes.minutes
    else
      # Format like "09:00 AM" - parse in timezone
      start_time_obj = Time.zone.parse("#{date} #{start_time}")
    end

    end_time_obj = start_time_obj + duration_minutes.minutes

    entry.schedule_blocks.destroy_all

    ScheduleBlock.create!(
      schedule_day: schedule_day,
      contest_entry: entry,
      performance_phase: phase,
      room: room,
      account: schedule_day.schedule.contest.account,
      start_time: start_time_obj,
      end_time: end_time_obj
    )

    entry
  end

  def assert_entry_scheduled_at(entry, expected_day:, expected_start_time:, expected_duration: nil)
    entry.reload
    block = entry.schedule_blocks.first

    assert_not_nil block, "Entry should have a schedule block"
    assert_equal expected_day.id, block.schedule_day_id, "Entry should be on expected day"

    expected_time_obj = Time.zone.parse(expected_start_time)
    assert_equal expected_time_obj.strftime("%H:%M"), block.start_time.strftime("%H:%M"),
                 "Entry should start at #{expected_start_time}"

    if expected_duration
      expected_end = expected_time_obj + expected_duration.minutes
      assert_equal expected_end.strftime("%H:%M"), block.end_time.strftime("%H:%M"),
                   "Entry duration should be #{expected_duration} minutes"
    end
  end

  def assert_entry_not_scheduled(entry)
    entry.reload
    assert_empty entry.schedule_blocks, "Entry should not have any schedule blocks"
  end
end
