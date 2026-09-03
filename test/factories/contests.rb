FactoryBot.define do
  factory :contest do
    account { Current.effective_account || association(:account) }
    season { association :season, account: account }
    sequence(:name) { |n| "Contest #{n}" }
    required_prescribed_count { 1 }
    required_custom_count { 2 }
    contest_start { Date.new(2026, 10, 1) }
    contest_end { Date.new(2026, 10, 3) }
    entry_deadline { Date.new(2026, 9, 1) }
  end
end
