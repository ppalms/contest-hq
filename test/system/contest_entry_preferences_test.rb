require "application_system_test_case"

class ContestEntryPreferencesTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, :director)
    set_current_user(@user)
    @contest = create(:contest, account: @user.account)
    @large_ensemble = create(:large_ensemble, account: @user.account)

    log_in_as(@user)
  end

  test "director can specify time preferences during registration" do
    visit contest_path(@contest)
    click_on "Register"

    assert_selector "form#contest_entry_form"

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
    entry = create(:contest_entry, contest: @contest, user: @user, large_ensemble: @large_ensemble, account: @user.account)
    entry.update!(preferred_time_start: Time.utc(2000, 1, 1, 16, 0), preferred_time_end: Time.utc(2000, 1, 1, 21, 0))

    visit contest_entry_path(@contest, entry)

    # Should see current preferences
    assert_text "Preferred Performance Time"
    assert_text "10:00 AM - 3:00 PM"

    click_on "Edit", match: :first

    # Update preferences
    assert_selector "form#contest_entry_form"
    fill_in "Earliest preferred time", with: "11:00"
    fill_in "Latest preferred time", with: "13:00"

    click_on "Update"

    # Should see updated preferences
    assert_text "11:00 AM - 1:00 PM"
  end

  test "preferences are optional during registration" do
    visit contest_path(@contest)
    click_on "Register"

    assert_selector "form#contest_entry_form"

    select @large_ensemble.name, from: :large_ensemble_id

    # Don't fill in any preferences
    click_on "Continue"

    # Should still complete registration successfully
    assert_text @large_ensemble.name
    assert_no_text "Preferred Performance Time"
  end
end
