namespace :schedule do
  desc "Manually clean up and regenerate schedule 4"
  task fix: :environment do
    schedule = Schedule.find(4)
    Current.account = schedule.contest.account

    puts "Current state:"
    puts "  Days: #{schedule.schedule_days.count}"
    puts "  Blocks: #{ScheduleBlock.where(schedule_day: schedule.schedule_days).count}"

    puts "\nCleaning up..."
    day_ids = schedule.schedule_days.pluck(:id)
    ScheduleBlock.where(schedule_day_id: day_ids).delete_all
    schedule.schedule_days.delete_all
    schedule.reload

    puts "After cleanup:"
    puts "  Days: #{schedule.schedule_days.count}"
    puts "  Blocks: #{ScheduleBlock.where(schedule_day_id: day_ids).count}"

    puts "\nGenerating schedule..."
    start_time = DateTime.parse("2026-02-14 08:00:00 -0600").utc
    end_time = DateTime.parse("2026-02-14 17:00:00 -0600").utc

    service = ScheduleGenerationService.new(schedule, start_time, end_time)
    service.call

    schedule.reload
    puts "\nAfter generation:"
    puts "  Days: #{schedule.schedule_days.count}"
    puts "  Blocks: #{ScheduleBlock.where(schedule_day: schedule.schedule_days).count}"
    puts "\nSuccess!"
  rescue => e
    puts "\nError: #{e.message}"
    puts e.backtrace.first(5)
  end
end
