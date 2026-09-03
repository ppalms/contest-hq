FactoryBot.define do
  factory :user do
    account { Current.effective_account || association(:account) }
    sequence(:email) { |n| "user#{n}@example.com" }
    first_name { "Test" }
    last_name { "User" }
    password { TEST_PASSWORD }
    time_zone { "America/Chicago" }
    verified { true }

    trait :sys_admin do
      after(:create) { |user| create(:user_role, user: user, role: create(:role, :sys_admin)) }
    end

    trait :account_admin do
      after(:create) { |user| create(:user_role, user: user, role: create(:role, :account_admin)) }
    end

    trait :director do
      after(:create) { |user| create(:user_role, user: user, role: create(:role, :director)) }
    end

    trait :manager do
      after(:create) { |user| create(:user_role, user: user, role: create(:role, :manager)) }
    end

    trait :judge do
      after(:create) { |user| create(:user_role, user: user, role: create(:role, :judge)) }
    end
  end
end
