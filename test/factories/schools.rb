FactoryBot.define do
  factory :school do
    account { Current.effective_account || association(:account) }
    school_class { association :school_class, account: account }
    sequence(:name) { |n| "School #{n}" }
  end
end
