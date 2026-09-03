FactoryBot.define do
  factory :contests_school_class do
    account { Current.effective_account || association(:account) }
    contest { association :contest, account: account }
    school_class { association :school_class, account: account }
  end
end
