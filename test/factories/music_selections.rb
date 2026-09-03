FactoryBot.define do
  factory :music_selection do
    account { contest_entry&.account || Current.effective_account || association(:account) }
    contest_entry { association :contest_entry, account: account }
    sequence(:title) { |n| "Music #{n}" }
    sequence(:composer) { |n| "Composer #{n}" }
    position { 1 }

    trait :prescribed do
      prescribed_music do
        entry = contest_entry
        create(:prescribed_music,
          account: account,
          season: entry.contest.season,
          school_class: entry.large_ensemble.school.school_class)
      end
    end
  end
end
