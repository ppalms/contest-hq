FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role#{n}" }
    sequence(:display_name) { |n| "Role #{n}" }

    trait :sys_admin do
      name { "SysAdmin" }
      display_name { "System Admin" }
    end

    trait :account_admin do
      name { "AccountAdmin" }
      display_name { "Account Admin" }
    end

    trait :director do
      name { "Director" }
      display_name { "Director" }
    end

    trait :manager do
      name { "Manager" }
      display_name { "Manager" }
    end

    trait :judge do
      name { "Judge" }
      display_name { "Judge" }
    end

    initialize_with { Role.find_or_initialize_by(name: name) }
  end
end
