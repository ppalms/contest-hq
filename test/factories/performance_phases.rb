FactoryBot.define do
  factory :performance_phase do
    account { Current.effective_account || association(:account) }
    contest { association :contest, account: account }
    room { association :room, contest: contest, account: account }
    sequence(:name) { |n| "Phase #{n}" }
    sequence(:ordinal) { |n| n }
    duration { 20 }
  end
end
