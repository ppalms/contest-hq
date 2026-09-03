FactoryBot.define do
  factory :schedule do
    account { Current.effective_account || association(:account) }
    contest { association :contest, account: account }
  end
end
