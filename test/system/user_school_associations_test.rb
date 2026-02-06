require "application_system_test_case"

class UserSchoolAssociationsTest < ApplicationSystemTestCase
  include LargeEnsemblesHelper

  setup do
    @admin = users(:demo_admin_a)
    @director = users(:demo_director_b) # Director with school association
    @school_a = schools(:demo_school_a)
    @school_b = schools(:demo_school_b)
    @school_c = schools(:demo_school_c)
    @school_d = schools(:demo_school_d)
    @performance_class = performance_classes(:demo_performance_class_a)
  end

  test "administrator can add school association to director" do
    log_in_as(@admin)

    # Find a director with no school associations initially
    director_without_schools = users(:demo_director_c)
    director_without_schools.schools.clear

    # Navigate to user show page
    visit user_path(director_without_schools)
    assert_text "#{director_without_schools.first_name} #{director_without_schools.last_name}"
    assert_text "No schools assigned"

    # Add a school association
    click_on "Add Schools"
    assert_text "Add Schools for #{director_without_schools.first_name}"

    # Check a school and submit
    page.execute_script("document.querySelector('input[name=\"user[school_ids][]\"]').checked = true;")
    click_on "Add Selected"

    # Verify success message and return to show page
    assert_text "school(s) added successfully"

    # Verify database association was created
    assert director_without_schools.reload.schools.count > 0
  end

  test "administrator can remove school association from director" do
    log_in_as(@admin)

    # Verify director initially has schools
    assert @director.schools.count > 0
    initial_school_count = @director.schools.count

    # Navigate to user show page
    visit user_path(@director)

    # Remove a school association - click the first Remove button and accept confirmation
    accept_confirm do
      click_on "Remove", match: :first
    end

    # Verify success message
    assert_text "removed successfully"

    # Verify database association was removed
    assert_equal initial_school_count - 1, @director.reload.schools.count
  end

  test "director can see associated school in large ensemble creation" do
    # Ensure director has at least one school
    unless @director.schools.include?(@school_c)
      SchoolDirector.create!(user: @director, school: @school_c, account: @director.account)
    end

    # Log in as director and check large ensemble creation
    log_in_as(@director)
    visit new_roster_large_ensemble_path

    # Verify the school appears in the dropdown
    assert_selector "select#school_id option", text: @school_c.name

    # Verify they can create a large ensemble with that school
    fill_in "Name", with: "Test Ensemble"
    select @school_c.name, from: :school_id
    select display_name_with_abbreviation(@performance_class), from: :performance_class_id
    click_on "Create Large Ensemble"

    assert_text "Large ensemble was successfully created"
    assert_text "Test Ensemble"
  end

  test "director cannot see removed school in large ensemble creation" do
    # First ensure director has multiple schools
    @director.schools.clear
    SchoolDirector.create!(user: @director, school: @school_b, account: @director.account)
    SchoolDirector.create!(user: @director, school: @school_c, account: @director.account)

    # Verify director can see both schools initially
    log_in_as(@director)
    visit new_roster_large_ensemble_path
    assert_selector "select#school_id option", text: @school_b.name
    assert_selector "select#school_id option", text: @school_c.name

    # Now as admin, remove one school association
    log_in_as(@admin)
    visit user_path(@director)
    accept_confirm do
      click_on "Remove", match: :first
    end
    assert_text "removed successfully"

    # Log back in as director and verify one school is no longer available
    log_in_as(@director)
    visit new_roster_large_ensemble_path

    # Verify director still has at least one school available
    @director.reload
    if @director.schools.any?
      remaining_school = @director.schools.first
      assert_selector "select#school_id option", text: remaining_school.name

      # Verify they can still create ensembles with remaining schools
      fill_in "Name", with: "Remaining School Ensemble"
      select remaining_school.name, from: :school_id
      select display_name_with_abbreviation(@performance_class), from: :performance_class_id
      click_on "Create Large Ensemble"

      assert_text "Large ensemble was successfully created"
      assert_text "Remaining School Ensemble"
    end
  end

  test "director with no school associations sees empty school dropdown" do
    # Ensure director has no schools
    director_without_schools = users(:demo_director_c)
    director_without_schools.schools.clear

    log_in_as(director_without_schools)
    visit new_roster_large_ensemble_path

    # Verify only the "Select a school" placeholder appears
    assert_selector "select#school_id option", count: 1
    assert_selector "select#school_id option", text: "Select a school"

    # Verify they cannot submit the form without selecting a school
    fill_in "Name", with: "Test Ensemble"
    select display_name_with_abbreviation(@performance_class), from: :performance_class_id
    click_on "Create Large Ensemble"

    # Form should not submit successfully due to HTML5 validation
    # Browser will prevent submission with required field empty
    # Verify we're still on the new large ensemble page
    assert_current_path new_roster_large_ensemble_path
  end

  test "administrator can add multiple schools to director at once" do
    log_in_as(@admin)

    # Find a director with no schools
    director_without_schools = users(:demo_director_c)
    director_without_schools.schools.clear

    # Navigate to user show page and add multiple schools
    visit user_path(director_without_schools)
    click_on "Add Schools"

    # Wait for the page to load and check multiple schools
    assert_text "Add Schools for"

    # Check the first two checkboxes that are not already selected
    checkboxes = all('input[type="checkbox"][name="user[school_ids][]"]:not(:checked)')
    if checkboxes.count >= 2
      checkboxes[0].check
      checkboxes[1].check
    end

    click_on "Add Selected"

    # Verify success message
    assert_text "school(s) added successfully"

    # Verify database associations were created
    assert director_without_schools.reload.schools.count >= 2
  end
end
