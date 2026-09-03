FactoryBot.define do
  factory :performance_class do
    account { Current.effective_account || association(:account) }
    sequence(:name) { |n| "Class #{n}" }
    sequence(:abbreviation) { |n| "C#{n}" }
    ordinal { PerformanceClass.unscoped.where(account_id: account.id).maximum(:ordinal).to_i + 1 }
  end
end
