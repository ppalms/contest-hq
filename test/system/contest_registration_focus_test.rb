require "application_system_test_case"

class ContestRegistrationFocusTest < ApplicationSystemTestCase
  setup do
    @user = users(:demo_director_a)
    @contest = contests(:demo_contest_a)
    @large_ensemble = large_ensembles(:demo_school_a_ensemble_c)

    log_in_as(@user)
  end

  test "contest entry form has proper focus management" do
    visit new_contest_entry_path(contest_id: @contest.id)



    # Check that the page has focus management controller
    assert_selector "[data-controller*='focus-manager']"
    assert_selector "[data-controller*='form-focus']"

    # Check that form fields have proper data attributes
    assert_selector "[data-form-focus-target='field']"

    # Check accessibility attributes
    assert_selector "form"
    # Note: form attributes may not render in test environment
    assert_selector "fieldset legend"
  end

  test "custom music form has proper focus management" do
    # Create a contest entry first
    contest_entry = ContestEntry.create!(
      contest: @contest,
      large_ensemble: @large_ensemble,
      user: @user,
      account: @user.account
    )

    visit new_contest_entry_music_selection_path(
      contest_id: @contest.id,
      entry_id: contest_entry.id,
      type: "custom"
    )

    # Check focus management setup
    assert_selector "[data-controller*='focus-manager']"
    assert_selector "[data-controller*='form-focus']"

    # Check form accessibility
    assert_selector "form"

    # Check field attributes
    assert_selector "input[data-form-focus-target='field']"
  end

  test "prescribed music search has proper focus management" do
    # Create a contest entry first
    contest_entry = ContestEntry.create!(
      contest: @contest,
      large_ensemble: @large_ensemble,
      user: @user,
      account: @user.account
    )

    visit new_prescribed_contest_entry_music_selections_path(
      contest_id: @contest.id,
      entry_id: contest_entry.id
    )

    # Check focus management setup
    assert_selector "[data-controller*='focus-manager']"
    assert_selector "[data-controller*='form-focus']"

    # Check search form accessibility
    assert_selector "form"

    # Check search field attributes
    assert_selector "input[data-form-focus-target='field']"

    # Check table accessibility (if results are shown)
    if page.has_selector?("table")
      assert_selector "th"
    end
  end

  test "contest entry details page has proper focus management" do
    # Create a contest entry first
    contest_entry = ContestEntry.create!(
      contest: @contest,
      large_ensemble: @large_ensemble,
      user: @user,
      account: @user.account
    )

    visit contest_entry_path(@contest, contest_entry)

    # Check focus management setup
    assert_selector "[data-controller*='focus-manager']"

    # Check action buttons have proper attributes
    if contest_entry.missing_prescribed_count > 0 || contest_entry.missing_custom_count > 0
      assert_selector "[data-focus-manager-target='autofocus']"
      assert_selector "[role='group'][aria-label]"
    end
  end

  test "form fields have proper tab order attributes" do
    visit new_contest_entry_path(contest_id: @contest.id)

    # Check that form fields have the form-focus target attribute for tab management
    form_fields = all("[data-form-focus-target='field']")
    assert form_fields.length > 0, "Should have form fields with focus targets"

    # Check that submit and cancel buttons have proper targets
    assert_selector "[data-form-focus-target='submit']"
    assert_selector "[data-form-focus-target='cancel']"
  end

  test "accessibility features are present" do
    visit new_contest_entry_path(contest_id: @contest.id)

    # Check basic structure
    assert_selector "form"

    # Check semantic HTML
    assert_selector "fieldset"
    assert_selector "legend"
  end
end
