FactoryBot.define do
  factory :performance_class do
    account { Current.effective_account || association(:account) }
    sequence(:name) { |n| "Class #{n}" }
    sequence(:ordinal) { |n| n }
  end
end
