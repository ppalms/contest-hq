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
end
