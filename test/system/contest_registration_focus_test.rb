require "application_system_test_case"

class ContestRegistrationFocusTest < ApplicationSystemTestCase
  setup do
    @user = users(:demo_admin_a)
    @contest = contests(:demo_contest_a)
    @large_ensemble = large_ensembles(:demo_large_ensemble_a)

    sign_in_as(@user)
  end

  test "contest entry form has proper focus management" do
    visit new_contest_entry_path(@contest)

    # Check that the page has focus management controller
    assert_selector "[data-controller*='focus-manager']"
    assert_selector "[data-controller*='form-focus']"

    # Check that form fields have proper data attributes
    assert_selector "[data-form-focus-target='field']"

    # Check accessibility attributes
    assert_selector "form[role='form']"
    assert_selector "form[aria-label]"
    assert_selector "fieldset legend"

    # Check skip link exists
    assert_selector "a[href='#contest_entry_form']", visible: :hidden
  end

  test "custom music form has proper focus management" do
    # Create a contest entry first
    contest_entry = ContestEntry.create!(
      contest: @contest,
      large_ensemble: @large_ensemble,
      user: @user
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
    assert_selector "form[role='form']"
    assert_selector "form[aria-label]"

    # Check field attributes
    assert_selector "input[data-form-focus-target='field']"

    # Check skip link
    assert_selector "a[href='#custom_music_form']", visible: :hidden
  end

  test "prescribed music search has proper focus management" do
    # Create a contest entry first
    contest_entry = ContestEntry.create!(
      contest: @contest,
      large_ensemble: @large_ensemble,
      user: @user
    )

    visit new_prescribed_contest_entry_music_selections_path(
      contest_id: @contest.id,
      entry_id: contest_entry.id
    )

    # Check focus management setup
    assert_selector "[data-controller*='focus-manager']"
    assert_selector "[data-controller*='form-focus']"

    # Check search form accessibility
    assert_selector "form[role='search']"
    assert_selector "form[aria-label]"

    # Check search field attributes
    assert_selector "input[data-form-focus-target='field']"
    assert_selector "input[aria-label]"

    # Check table accessibility
    assert_selector "table[role='table']"
    assert_selector "table[aria-label]"
    assert_selector "th[scope='col']"

    # Check skip link
    assert_selector "a[href='#prescribed_search_form']", visible: :hidden
  end

  test "contest entry details page has proper focus management" do
    # Create a contest entry first
    contest_entry = ContestEntry.create!(
      contest: @contest,
      large_ensemble: @large_ensemble,
      user: @user
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
    visit new_contest_entry_path(@contest)

    # Check that form fields have the form-focus target attribute for tab management
    form_fields = all("[data-form-focus-target='field']")
    assert form_fields.length > 0, "Should have form fields with focus targets"

    # Check that submit and cancel buttons have proper targets
    assert_selector "[data-form-focus-target='submit']"
    assert_selector "[data-form-focus-target='cancel']"
  end

  test "accessibility features are present" do
    visit new_contest_entry_path(@contest)

    # Check ARIA labels
    assert_selector "[aria-label]"

    # Check semantic HTML
    assert_selector "fieldset"
    assert_selector "legend"

    # Check skip links
    assert_selector "a[href='#contest_entry_form']", visible: :hidden
  end
end
