require "test_helper"

class ContestEntryTest < ActiveSupport::TestCase
  setup do
    @contest_entry = contest_entries(:contest_a_school_a_ensemble_b)
    @contest = @contest_entry.contest
  end

  test "should validate preferred time within contest hours" do
    # Set contest times for validation
    @contest.update!(start_time: "08:00", end_time: "17:00")

    # Valid preferences within contest hours
    @contest_entry.preferred_time_start = "09:00"
    @contest_entry.preferred_time_end = "16:00"
    assert @contest_entry.valid?

    # Invalid preference before contest start
    @contest_entry.preferred_time_start = "07:00"
    assert_not @contest_entry.valid?
    assert @contest_entry.errors[:preferred_time_start].any?

    # Invalid preference after contest end
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

    # Within range
    schedule_time = DateTime.parse("2024-01-01 12:00:00")
    assert @contest_entry.within_preferred_time?(schedule_time)

    # Before range
    schedule_time = DateTime.parse("2024-01-01 08:00:00")
    assert_not @contest_entry.within_preferred_time?(schedule_time)

    # After range
    schedule_time = DateTime.parse("2024-01-01 16:00:00")
    assert_not @contest_entry.within_preferred_time?(schedule_time)

    # No preference should return true
    @contest_entry.preferred_time_start = nil
    @contest_entry.preferred_time_end = nil
    assert @contest_entry.within_preferred_time?(schedule_time)
  end

  test "should validate school class eligibility for contest" do
    # demo_contest_c is restricted to 2A and 3A schools
    restricted_contest = contests(:demo_contest_c)

    # demo_school_a is a 1A school (Kennedy High School)
    ineligible_ensemble = large_ensembles(:demo_school_a_ensemble_a)

    # Create contest entry with ineligible ensemble
    entry = ContestEntry.new(
      contest: restricted_contest,
      user: users(:demo_director_a),
      large_ensemble: ineligible_ensemble
    )

    assert_not entry.valid?
    assert entry.errors[:large_ensemble].any?
    assert_match(/1-A school.*restricted to 2-A, 3-A schools/, entry.errors[:large_ensemble].first)
  end

  test "should allow contest entry when school class matches contest restriction" do
    # demo_contest_c is restricted to 2A and 3A schools
    restricted_contest = contests(:demo_contest_c)

    # demo_school_b is a 2A school (Washington High School)
    eligible_ensemble = large_ensembles(:demo_school_b_ensemble_a)

    # Create contest entry with eligible ensemble
    entry = ContestEntry.new(
      contest: restricted_contest,
      user: users(:demo_director_b),
      large_ensemble: eligible_ensemble
    )

    entry.valid?
    assert_not entry.errors[:large_ensemble].any?, "Expected no errors for eligible ensemble, but got: #{entry.errors[:large_ensemble].join(', ')}"
  end

  test "should allow all schools when contest has no restrictions" do
    # demo_contest_a has no school class restrictions (or all classes)
    unrestricted_contest = contests(:demo_contest_a)

    # Try with a 1A school ensemble
    ensemble = large_ensembles(:demo_school_a_ensemble_a)

    entry = ContestEntry.new(
      contest: unrestricted_contest,
      user: users(:demo_director_a),
      large_ensemble: ensemble
    )

    entry.valid?
    assert_not entry.errors[:large_ensemble].any?, "Expected no errors for unrestricted contest, but got: #{entry.errors[:large_ensemble].join(', ')}"
  end

  test "music_complete? returns true when entry has 1 prescribed and 2 custom pieces" do
    set_current_user(users(:demo_director_a))
    entry = contest_entries(:contest_a_school_a_ensemble_b)
    entry.music_selections.destroy_all

    assert_not entry.music_complete?

    entry.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed_musics(:demo_2024_class_a_music_one), position: 1)
    entry.music_selections.create!(title: "Symphony", composer: "Jones", position: 2)

    assert_not entry.music_complete?

    entry.music_selections.create!(title: "Overture", composer: "Brown", position: 3)

    assert entry.music_complete?
  end

  test "prescribed_selection returns the prescribed music selection" do
    set_current_user(users(:demo_director_a))
    entry = contest_entries(:contest_a_school_a_ensemble_b)
    entry.music_selections.destroy_all

    assert_nil entry.prescribed_selection

    prescribed = entry.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed_musics(:demo_2024_class_a_music_one), position: 1)
    entry.music_selections.create!(title: "Symphony", composer: "Jones", position: 2)

    assert_equal prescribed, entry.prescribed_selection
  end

  test "custom_selections returns only custom music selections" do
    set_current_user(users(:demo_director_a))
    entry = contest_entries(:contest_a_school_a_ensemble_b)

    entry.music_selections.destroy_all
    assert_equal 0, entry.custom_selections.count

    entry.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed_musics(:demo_2024_class_a_music_one), position: 1)
    custom1 = entry.music_selections.create!(title: "Symphony", composer: "Jones", position: 2)
    custom2 = entry.music_selections.create!(title: "Overture", composer: "Brown", position: 3)

    assert_equal 2, entry.custom_selections.count
    assert_includes entry.custom_selections, custom1
    assert_includes entry.custom_selections, custom2
  end

  test "previous_entry_in_season returns most recent entry for same ensemble in same season" do
    set_current_user(users(:demo_director_a))

    ensemble = large_ensembles(:demo_school_a_ensemble_c)

    contest_2024_a = contests(:demo_contest_a)
    contest_2024_b = contests(:demo_contest_b)

    entry_2024_a = ContestEntry.create!(contest: contest_2024_a, user: users(:demo_director_a), large_ensemble: ensemble)
    sleep 0.01
    entry_2024_b = ContestEntry.create!(contest: contest_2024_b, user: users(:demo_director_a), large_ensemble: ensemble)

    assert_equal entry_2024_a, entry_2024_b.previous_entry_in_season
  end

  test "music_complete? respects contest's required_prescribed_count" do
    set_current_user(users(:demo_director_a))
    @contest_entry.music_selections.destroy_all
    @contest.update!(required_prescribed_count: 2, required_custom_count: 1)

    @contest_entry.music_selections.create!(title: "March 1", composer: "Smith", prescribed_music: prescribed_musics(:demo_2024_class_a_music_one), position: 1)
    @contest_entry.music_selections.create!(title: "Custom", composer: "Jones", position: 2)

    assert_not @contest_entry.music_complete?, "Should not be complete with only 1 prescribed when 2 required"

    @contest_entry.music_selections.create!(title: "March 2", composer: "Brown", prescribed_music: prescribed_musics(:demo_2024_class_a_music_two), position: 3)

    assert @contest_entry.music_complete?, "Should be complete with 2 prescribed and 1 custom"
  end

  test "music_complete? respects contest's required_custom_count" do
    set_current_user(users(:demo_director_a))
    @contest_entry.music_selections.destroy_all
    @contest.update!(required_prescribed_count: 1, required_custom_count: 3)

    @contest_entry.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed_musics(:demo_2024_class_a_music_one), position: 1)
    @contest_entry.music_selections.create!(title: "Custom 1", composer: "Jones", position: 2)
    @contest_entry.music_selections.create!(title: "Custom 2", composer: "Brown", position: 3)

    assert_not @contest_entry.music_complete?, "Should not be complete with only 2 custom when 3 required"

    @contest_entry.music_selections.create!(title: "Custom 3", composer: "Davis", position: 4)

    assert @contest_entry.music_complete?, "Should be complete with 1 prescribed and 3 custom"
  end

  test "music_complete? returns false when missing prescribed selections" do
    set_current_user(users(:demo_director_a))
    @contest_entry.music_selections.destroy_all

    @contest_entry.music_selections.create!(title: "Custom 1", composer: "Jones", position: 1)
    @contest_entry.music_selections.create!(title: "Custom 2", composer: "Brown", position: 2)
    @contest_entry.music_selections.create!(title: "Custom 3", composer: "Davis", position: 3)

    assert_not @contest_entry.music_complete?, "Should not be complete without prescribed music"
  end

  test "music_complete? returns false when missing custom selections" do
    set_current_user(users(:demo_director_a))
    @contest_entry.music_selections.destroy_all

    @contest_entry.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed_musics(:demo_2024_class_a_music_one), position: 1)

    assert_not @contest_entry.music_complete?, "Should not be complete with only prescribed music"
  end

  test "required_music_slots returns array of slot definitions" do
    @contest.update!(required_prescribed_count: 2, required_custom_count: 1)

    slots = @contest_entry.required_music_slots

    assert_equal 3, slots.length
    assert_equal 2, slots.count { |s| s[:type] == :prescribed }
    assert_equal 1, slots.count { |s| s[:type] == :custom }
    assert_equal (1..3).to_a, slots.map { |s| s[:position] }
  end

  test "required_music_slots marks filled slots correctly" do
    set_current_user(users(:demo_director_a))
    @contest_entry.music_selections.destroy_all
    @contest.update!(required_prescribed_count: 1, required_custom_count: 2)

    @contest_entry.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed_musics(:demo_2024_class_a_music_one), position: 1)

    slots = @contest_entry.required_music_slots

    assert_equal 3, slots.length
    assert slots[0][:music_selection].present?, "First slot should have music selection"
    assert_nil slots[1][:music_selection], "Second slot should be empty"
    assert_nil slots[2][:music_selection], "Third slot should be empty"
  end

  test "missing_prescribed_count returns number of prescribed pieces needed" do
    set_current_user(users(:demo_director_a))
    @contest_entry.music_selections.destroy_all
    @contest.update!(required_prescribed_count: 2, required_custom_count: 1)

    assert_equal 2, @contest_entry.missing_prescribed_count

    @contest_entry.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed_musics(:demo_2024_class_a_music_one), position: 1)

    assert_equal 1, @contest_entry.missing_prescribed_count

    @contest_entry.music_selections.create!(title: "March 2", composer: "Brown", prescribed_music: prescribed_musics(:demo_2024_class_a_music_two), position: 2)

    assert_equal 0, @contest_entry.missing_prescribed_count
  end

  test "missing_custom_count returns number of custom pieces needed" do
    set_current_user(users(:demo_director_a))
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
