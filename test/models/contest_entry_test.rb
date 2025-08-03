require "test_helper"

class ContestEntryTest < ActiveSupport::TestCase
  setup do
    @contest_entry = contest_entries(:contest_a_school_a_ensemble_a)
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
end
