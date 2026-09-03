FactoryBot.define do
  factory :large_ensemble do
    account { Current.effective_account || association(:account) }
    school { association :school, account: account }
    performance_class { association :performance_class, account: account }
    sequence(:name) { |n| "Large Ensemble #{n}" }

    after(:build) do |ensemble|
      if Current.user.nil? || Current.user.account_id != ensemble.account_id
        user = create(:user, :director, account: ensemble.account)
        Current.session = OpenStruct.new(user: user)
      end
    end
  end
end
