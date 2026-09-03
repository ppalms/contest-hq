FactoryBot.define do
  factory :room do
    account { Current.effective_account || association(:account) }
    contest { association :contest, account: account }
    sequence(:name) { |n| "Room #{n}" }
    sequence(:room_number) { |n| n.to_s }
  end
end
