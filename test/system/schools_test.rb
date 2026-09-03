require "application_system_test_case"

class SchoolsTest < ApplicationSystemTestCase
  setup do
    @admin = create(:user, :account_admin)
    @school = create(:school, account: @admin.account, name: "Central High School")
    create(:school, account: @admin.account, name: "Washington High School")
    create(:school, account: @admin.account, name: "Kennedy High School")
    create(:school, account: @admin.account, name: "Memorial High School")
    customer_account = create(:account, name: "Customer")
    create(:school, account: customer_account, name: "Santa Fe High School")
    create(:school_class, account: @admin.account, name: "1-A", ordinal: 1)
    log_in_as(@admin)
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

    assert_selector "form.wide-form"

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

    assert_no_text "Santa Fe High School"
  end

  test "should not allow director to create" do
    log_in_as(create(:user, :director, account: @admin.account))
    visit organizations_schools_url
    assert_no_text "New School"

    visit new_organizations_school_url
    assert_text "You do not have permission to create schools."
  end

  test "should have search functionality" do
    visit organizations_schools_url
    assert_selector "input[placeholder='Search by school name']"
    assert_selector "input[value='Search']"
    assert_link "Reset"
  end

  test "should search schools by name" do
    visit organizations_schools_url
    fill_in "name", with: "Kennedy"
    click_on "Search"
    assert_text "Kennedy High School"
    assert_no_text "Washington High School"
  end

  test "schools should be sorted alphabetically by name" do
    visit organizations_schools_url
    school_names = all("p.font-semibold.text-gray-900").map(&:text)
    assert_equal school_names.sort, school_names, "Schools should be sorted alphabetically by name"
  end
end
