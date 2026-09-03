require "test_helper"

class ContestEntryTest < ActiveSupport::TestCase
  setup do
    @director = create(:user, :director)
    set_current_user(@director)
    @contest_entry = create(:contest_entry, user: @director)
    @contest = @contest_entry.contest
  end

  test "should validate preferred time within contest hours" do
    @contest.update!(start_time: "08:00", end_time: "17:00")

    @contest_entry.preferred_time_start = "09:00"
    @contest_entry.preferred_time_end = "16:00"
    assert @contest_entry.valid?

    @contest_entry.preferred_time_start = "07:00"
    assert_not @contest_entry.valid?
    assert @contest_entry.errors[:preferred_time_start].any?

    @contest_entry.preferred_time_start = "09:00"
    @contest_entry.preferred_time_end = "18:00"
    assert_not @contest_entry.valid?
    assert @contest_entry.errors[:preferred_time_end].any?
  end

  test "should validate end time after start time" do
    @contest.update!(start_time: "08:00", end_time: "17:00")

    @contest_entry.preferred_time_start = "14:00"
    @contest_entry.preferred_time_end = "10:00"
    assert_not @contest_entry.valid?
    assert @contest_entry.errors[:preferred_time_end].any?
  end

  test "has_time_preference? returns correct value" do
    assert_not @contest_entry.has_time_preference?

    @contest_entry.preferred_time_start = "09:00"
    assert @contest_entry.has_time_preference?

    @contest_entry.preferred_time_start = nil
    @contest_entry.preferred_time_end = "15:00"
    assert @contest_entry.has_time_preference?
  end

  test "full_time_preference? returns correct value" do
    assert_not @contest_entry.full_time_preference?

    @contest_entry.preferred_time_start = "09:00"
    assert_not @contest_entry.full_time_preference?

    @contest_entry.preferred_time_end = "15:00"
    assert @contest_entry.full_time_preference?
  end

  test "within_preferred_time? checks correctly" do
    @contest_entry.preferred_time_start = "09:00"
    @contest_entry.preferred_time_end = "15:00"

    schedule_time = DateTime.parse("2024-01-01 12:00:00")
    assert @contest_entry.within_preferred_time?(schedule_time)

    schedule_time = DateTime.parse("2024-01-01 08:00:00")
    assert_not @contest_entry.within_preferred_time?(schedule_time)

    schedule_time = DateTime.parse("2024-01-01 16:00:00")
    assert_not @contest_entry.within_preferred_time?(schedule_time)

    @contest_entry.preferred_time_start = nil
    @contest_entry.preferred_time_end = nil
    assert @contest_entry.within_preferred_time?(schedule_time)
  end

  test "should validate school class eligibility for contest" do
    account = @contest.account
    restricted_contest = create(:contest, account: account)
    class_2a = create(:school_class, name: "2-A", account: account)
    class_3a = create(:school_class, name: "3-A", account: account)
    restricted_contest.school_classes << [ class_2a, class_3a ]

    school_1a = create(:school, account: account, school_class: create(:school_class, name: "1-A", account: account))
    ineligible_ensemble = create(:large_ensemble, account: account, school: school_1a)

    entry = ContestEntry.new(
      contest: restricted_contest,
      user: @director,
      large_ensemble: ineligible_ensemble
    )

    assert_not entry.valid?
    assert entry.errors[:large_ensemble].any?
    assert_match(/1-A school.*restricted to 2-A, 3-A schools/, entry.errors[:large_ensemble].first)
  end

  test "should allow contest entry when school class matches contest restriction" do
    account = @contest.account
    restricted_contest = create(:contest, account: account)
    class_2a = create(:school_class, name: "2-A", account: account)
    class_3a = create(:school_class, name: "3-A", account: account)
    restricted_contest.school_classes << [ class_2a, class_3a ]

    school_2a = create(:school, account: account, school_class: class_2a)
    eligible_ensemble = create(:large_ensemble, account: account, school: school_2a)

    entry = ContestEntry.new(
      contest: restricted_contest,
      user: @director,
      large_ensemble: eligible_ensemble
    )

    entry.valid?
    assert_not entry.errors[:large_ensemble].any?, "Expected no errors for eligible ensemble, but got: #{entry.errors[:large_ensemble].join(', ')}"
  end

  test "should allow all schools when contest has no restrictions" do
    account = @contest.account
    unrestricted_contest = create(:contest, account: account)

    school_1a = create(:school, account: account, school_class: create(:school_class, name: "1-A", account: account))
    ensemble = create(:large_ensemble, account: account, school: school_1a)

    entry = ContestEntry.new(
      contest: unrestricted_contest,
      user: @director,
      large_ensemble: ensemble
    )

    entry.valid?
    assert_not entry.errors[:large_ensemble].any?, "Expected no errors for unrestricted contest, but got: #{entry.errors[:large_ensemble].join(', ')}"
  end

  test "music_complete? returns true when entry has 1 prescribed and 2 custom pieces" do
    entry = create(:contest_entry, user: @director)
    entry.music_selections.destroy_all

    assert_not entry.music_complete?

    prescribed = create(:prescribed_music,
      account: entry.account,
      season: entry.contest.season,
      school_class: entry.large_ensemble.school.school_class)
    entry.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed, position: 1)
    entry.music_selections.create!(title: "Symphony", composer: "Jones", position: 2)

    assert_not entry.music_complete?

    entry.music_selections.create!(title: "Overture", composer: "Brown", position: 3)

    assert entry.music_complete?
  end

  test "prescribed_selection returns the prescribed music selection" do
    entry = create(:contest_entry, user: @director)
    entry.music_selections.destroy_all

    assert_nil entry.prescribed_selection

    prescribed = create(:prescribed_music,
      account: entry.account,
      season: entry.contest.season,
      school_class: entry.large_ensemble.school.school_class)
    prescribed_selection = entry.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed, position: 1)
    entry.music_selections.create!(title: "Symphony", composer: "Jones", position: 2)

    assert_equal prescribed_selection, entry.prescribed_selection
  end

  test "custom_selections returns only custom music selections" do
    entry = create(:contest_entry, user: @director)

    entry.music_selections.destroy_all
    assert_equal 0, entry.custom_selections.count

    prescribed = create(:prescribed_music,
      account: entry.account,
      season: entry.contest.season,
      school_class: entry.large_ensemble.school.school_class)
    entry.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed, position: 1)
    custom1 = entry.music_selections.create!(title: "Symphony", composer: "Jones", position: 2)
    custom2 = entry.music_selections.create!(title: "Overture", composer: "Brown", position: 3)

    assert_equal 2, entry.custom_selections.count
    assert_includes entry.custom_selections, custom1
    assert_includes entry.custom_selections, custom2
  end

  test "previous_entry_in_season returns most recent entry for same ensemble in same season" do
    account = @contest.account
    ensemble = create(:large_ensemble, account: account)
    season = create(:season, account: account)

    contest_2024_a = create(:contest, account: account, season: season)
    contest_2024_b = create(:contest, account: account, season: season)

    entry_2024_a = ContestEntry.create!(contest: contest_2024_a, user: @director, large_ensemble: ensemble)
    sleep 0.01
    entry_2024_b = ContestEntry.create!(contest: contest_2024_b, user: @director, large_ensemble: ensemble)

    assert_equal entry_2024_a, entry_2024_b.previous_entry_in_season
  end

  test "music_complete? respects contest's required_prescribed_count" do
    @contest_entry.music_selections.destroy_all
    @contest.update!(required_prescribed_count: 2, required_custom_count: 1)

    prescribed1 = create(:prescribed_music,
      account: @contest_entry.account,
      season: @contest_entry.contest.season,
      school_class: @contest_entry.large_ensemble.school.school_class)
    prescribed2 = create(:prescribed_music,
      account: @contest_entry.account,
      season: @contest_entry.contest.season,
      school_class: @contest_entry.large_ensemble.school.school_class)

    @contest_entry.music_selections.create!(title: "March 1", composer: "Smith", prescribed_music: prescribed1, position: 1)
    @contest_entry.music_selections.create!(title: "Custom", composer: "Jones", position: 2)

    assert_not @contest_entry.music_complete?, "Should not be complete with only 1 prescribed when 2 required"

    @contest_entry.music_selections.create!(title: "March 2", composer: "Brown", prescribed_music: prescribed2, position: 3)

    assert @contest_entry.music_complete?, "Should be complete with 2 prescribed and 1 custom"
  end

  test "music_complete? respects contest's required_custom_count" do
    @contest_entry.music_selections.destroy_all
    @contest.update!(required_prescribed_count: 1, required_custom_count: 3)

    prescribed = create(:prescribed_music,
      account: @contest_entry.account,
      season: @contest_entry.contest.season,
      school_class: @contest_entry.large_ensemble.school.school_class)

    @contest_entry.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed, position: 1)
    @contest_entry.music_selections.create!(title: "Custom 1", composer: "Jones", position: 2)
    @contest_entry.music_selections.create!(title: "Custom 2", composer: "Brown", position: 3)

    assert_not @contest_entry.music_complete?, "Should not be complete with only 2 custom when 3 required"

    @contest_entry.music_selections.create!(title: "Custom 3", composer: "Davis", position: 4)

    assert @contest_entry.music_complete?, "Should be complete with 1 prescribed and 3 custom"
  end

  test "music_complete? returns false when missing prescribed selections" do
    @contest_entry.music_selections.destroy_all

    @contest_entry.music_selections.create!(title: "Custom 1", composer: "Jones", position: 1)
    @contest_entry.music_selections.create!(title: "Custom 2", composer: "Brown", position: 2)
    @contest_entry.music_selections.create!(title: "Custom 3", composer: "Davis", position: 3)

    assert_not @contest_entry.music_complete?, "Should not be complete without prescribed music"
  end

  test "music_complete? returns false when missing custom selections" do
    @contest_entry.music_selections.destroy_all

    prescribed = create(:prescribed_music,
      account: @contest_entry.account,
      season: @contest_entry.contest.season,
      school_class: @contest_entry.large_ensemble.school.school_class)
    @contest_entry.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed, position: 1)

    assert_not @contest_entry.music_complete?, "Should not be complete with only prescribed music"
  end

  test "missing_prescribed_count returns number of prescribed pieces needed" do
    @contest_entry.music_selections.destroy_all
    @contest.update!(required_prescribed_count: 2, required_custom_count: 1)

    assert_equal 2, @contest_entry.missing_prescribed_count

    prescribed1 = create(:prescribed_music,
      account: @contest_entry.account,
      season: @contest_entry.contest.season,
      school_class: @contest_entry.large_ensemble.school.school_class)
    @contest_entry.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed1, position: 1)

    assert_equal 1, @contest_entry.missing_prescribed_count

    prescribed2 = create(:prescribed_music,
      account: @contest_entry.account,
      season: @contest_entry.contest.season,
      school_class: @contest_entry.large_ensemble.school.school_class)
    @contest_entry.music_selections.create!(title: "March 2", composer: "Brown", prescribed_music: prescribed2, position: 2)

    assert_equal 0, @contest_entry.missing_prescribed_count
  end

  test "missing_custom_count returns number of custom pieces needed" do
    @contest_entry.music_selections.destroy_all
    @contest.update!(required_prescribed_count: 1, required_custom_count: 3)

    assert_equal 3, @contest_entry.missing_custom_count

    @contest_entry.music_selections.create!(title: "Custom 1", composer: "Jones", position: 1)

    assert_equal 2, @contest_entry.missing_custom_count

    @contest_entry.music_selections.create!(title: "Custom 2", composer: "Brown", position: 2)
    @contest_entry.music_selections.create!(title: "Custom 3", composer: "Davis", position: 3)

    assert_equal 0, @contest_entry.missing_custom_count
  end
end
