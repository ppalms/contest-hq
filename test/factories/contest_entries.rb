FactoryBot.define do
  factory :contest_entry do
    account { Current.effective_account || association(:account) }
    user { association :user, account: account }
    contest { association :contest, account: account }
    large_ensemble { association :large_ensemble, account: account }

    after(:build) do |entry|
      if entry.contest && entry.large_ensemble
        school_class = entry.large_ensemble.school.school_class
        unless entry.contest.school_classes.include?(school_class)
          entry.contest.school_classes << school_class
        end
      end
    end
  end
end
