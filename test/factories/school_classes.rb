FactoryBot.define do
  factory :school_class do
    account { Current.effective_account || association(:account) }
    sequence(:name) { |n| "Class #{n}" }
    ordinal { SchoolClass.unscoped.where(account_id: account.id).maximum(:ordinal).to_i + 1 }
  end
end
