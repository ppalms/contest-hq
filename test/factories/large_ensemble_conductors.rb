FactoryBot.define do
  factory :large_ensemble_conductor do
    account { Current.effective_account || association(:account) }
    user { association :user, account: account }
    large_ensemble { association :large_ensemble, account: account }
  end
end
