FactoryBot.define do
  factory :schedule_day do
    account { Current.effective_account || association(:account) }
    schedule { association :schedule, account: account }
    schedule_date { Date.new(2026, 10, 1) }
    start_time { Time.zone.parse("2026-10-01 08:00:00") }
    end_time { Time.zone.parse("2026-10-01 17:00:00") }
  end
end
