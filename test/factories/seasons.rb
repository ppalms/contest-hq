FactoryBot.define do
  factory :season do
    account { Current.effective_account || association(:account) }
    sequence(:name) { |n| "Season #{n}" }
    sequence(:ordinal) { |n| n }
    archived { false }
  end
end
