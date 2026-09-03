FactoryBot.define do
  factory :school_director do
    account { Current.effective_account || association(:account) }
    user { association :user, account: account }
    school { association :school, account: account }
  end
end
