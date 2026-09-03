FactoryBot.define do
  factory :prescribed_music do
    account { Current.effective_account || association(:account) }
    season { association :season, account: account }
    school_class { association :school_class, account: account }
    sequence(:title) { |n| "Prescribed Music #{n}" }
    sequence(:composer) { |n| "Composer #{n}" }
  end
end
