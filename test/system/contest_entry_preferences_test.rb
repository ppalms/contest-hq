require "application_system_test_case"

class ContestEntryPreferencesTest < ApplicationSystemTestCase
  setup do
    log_in_as(users(:demo_director_a))
    @contest = contests(:demo_contest_a)
    @large_ensemble = large_ensembles(:demo_school_a_ensemble_a)
  end

  test "director can specify time preferences during registration" do
    visit contest_path(@contest)
    click_on "Register"
    
    select @large_ensemble.name, from: "Large ensemble"
    
    # Fill in time preferences
    fill_in "Earliest preferred time", with: "09:00"
    fill_in "Latest preferred time", with: "14:00"
    
    click_on "Continue"
    
    # Should see the preferences displayed
    assert_text "Preferred Performance Time"
    assert_text "9:00 AM - 2:00 PM"
  end

  test "director can edit time preferences after registration" do
    # Create an entry first
    entry = ContestEntry.create!(
      contest: @contest,
      user: users(:demo_director_a),
      large_ensemble: @large_ensemble,
      preferred_time_start: "10:00",
      preferred_time_end: "15:00"
    )
    
    visit contest_entry_path(entry)
    
    # Should see current preferences
    assert_text "Preferred Performance Time"
    assert_text "10:00 AM - 3:00 PM"
    
    click_on "Edit"
    
    # Update preferences
    fill_in "Earliest preferred time", with: "11:00"
    fill_in "Latest preferred time", with: "13:00"
    
    click_on "Continue"
    
    # Should see updated preferences
    assert_text "11:00 AM - 1:00 PM"
  end

  test "preferences are optional during registration" do
    visit contest_path(@contest)
    click_on "Register"
    
    select @large_ensemble.name, from: "Large ensemble"
    
    # Don't fill in any preferences
    click_on "Continue"
    
    # Should still complete registration successfully
    assert_text @large_ensemble.name
    assert_no_text "Preferred Performance Time"
  end

  private

  def log_in_as(user)
    visit sign_in_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "Secret1*3*5*"
    click_on "Sign in"
  end
end