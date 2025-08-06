require "application_system_test_case"

class ContestEntryPreferencesTest < ApplicationSystemTestCase
  setup do
    log_in_as(users(:demo_director_a))
    @contest = contests(:demo_contest_a)
    @large_ensemble = large_ensembles(:demo_school_a_ensemble_c)
  end

  test "director can specify time preferences during registration" do
    visit contest_path(@contest)
    click_on "Register"

    select @large_ensemble.name, from: :large_ensemble_id

    # Fill in time preferences
    fill_in "Earliest preferred time", with: "13:00"
    fill_in "Latest preferred time", with: "14:00"

    click_on "Continue"

    # Should see the preferences displayed
    assert_text "Preferred Performance Time"
    assert_text "1:00 PM - 2:00 PM"
  end

  test "director can edit time preferences after registration" do
    entry = contest_entries(:contest_a_school_a_ensemble_a)
    visit contest_entry_path(@contest, entry)

    # Should see current preferences
    assert_text "Preferred Performance Time"
    assert_text "10:00 AM - 3:00 PM"

    click_on "Edit"

    # Update preferences
    fill_in "Earliest preferred time", with: "11:00"
    fill_in "Latest preferred time", with: "13:00"

    click_on "Update"

    # Should see updated preferences
    assert_text "11:00 AM - 1:00 PM"
  end

  test "preferences are optional during registration" do
    visit contest_path(@contest)
    click_on "Register"

    select @large_ensemble.name, from: :large_ensemble_id

    # Don't fill in any preferences
    click_on "Continue"

    # Should still complete registration successfully
    assert_text @large_ensemble.name
    assert_no_text "Preferred Performance Time"
  end
end
