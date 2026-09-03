FactoryBot.define do
  factory :contest_manager do
    account { Current.effective_account || association(:account) }
    contest { association :contest, account: account }
    user { association :user, :manager, account: account }
  end
end
