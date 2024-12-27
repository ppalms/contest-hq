require "application_system_test_case"

class SchoolsTest < ApplicationSystemTestCase
  setup do
    log_in_as(users(:demo_admin_a))
    @school = schools(:demo_school_d)
  end

  test "visiting the index" do
    visit organizations_schools_url
    assert_selector "h1", text: "Schools"
    assert_text "Washington High School"
    assert_text "Kennedy High School"
    assert_text "Memorial High School"
    assert_text "Central High School"
  end

  test "should create school" do
    visit organizations_schools_url
    click_on "New School"

    fill_in "Name", with: "Unseen University"

    select "1-A", from: :school_class_id
    click_on "Create School"

    assert_text "School was successfully created"
    assert_text @school.name
  end

  test "should update school" do
    visit organizations_school_url(@school)
    click_on "Edit", match: :first

    fill_in "Name", with: "New School Name"
    click_on "Update School"

    assert_text "School was successfully updated"
    click_on "Schools"
    assert_text "New School Name"
  end

  test "should delete school" do
    visit organizations_school_url(@school)
    click_on "Delete", match: :first

    accept_confirm

    assert_text "School was successfully deleted"
    assert_no_text @school.name
  end

  test "showing an organization" do
    visit organizations_schools_url
    click_link(href: organizations_school_path(@school.id))

    assert_selector "h1", text: @school.name

    click_on "Schools"
  end

  test "should not see other account's schools" do
    visit organizations_schools_url

    # Can't see organization belonging to OSSAA account
    assert_no_text "Lincoln High School"
  end

  test "should not allow director to create" do
    log_in_as(users(:demo_director_a))
    visit organizations_schools_url
    assert_no_text "New School"

    visit new_organizations_school_url
    assert_text "You do not have permission to create schools."
  end
end
