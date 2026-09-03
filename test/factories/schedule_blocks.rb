FactoryBot.define do
  factory :schedule_block do
    account { Current.effective_account || association(:account) }
    schedule_day { association :schedule_day, account: account }
    contest_entry { association :contest_entry, account: account }
    room { association :room, contest: schedule_day.schedule.contest, account: account }
    start_time { Time.zone.parse("2026-10-01 08:00:00") }
    end_time { Time.zone.parse("2026-10-01 08:20:00") }
  end
end
