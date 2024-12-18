require "application_system_test_case"

class OrganizationsTest < ApplicationSystemTestCase
  setup do
    log_in_as(users(:demo_admin_a))
    @organization = organizations(:demo_school_d)
  end

  test "visiting the index" do
    visit organizations_url
    assert_selector "h1", text: "Organizations"
    assert_text "Washington High School"
    assert_text "Kennedy High School"
    assert_text "Memorial High School"
    assert_text "Central High School"
  end

  test "should create organization" do
    visit organizations_url
    click_on "New Organization"

    fill_in "Name", with: "Unseen University"

    select "School", from: :organization_type_id
    click_on "Create Organization"

    assert_text "Organization was successfully created"
    assert_text @organization.name
  end

  test "should update organization" do
    visit organization_url(@organization)
    click_on "Edit", match: :first

    fill_in "Name", with: "New School Name"
    click_on "Update Organization"

    assert_text "Organization was successfully updated"
    click_on "Organizations"
    assert_text "New School Name"
  end

  test "should delete organization" do
    visit organization_url(@organization)
    click_on "Delete", match: :first

    accept_confirm

    assert_text "Organization was successfully deleted"
    assert_no_text @organization.name
  end

  test "showing an organization" do
    visit organizations_url
    click_link(href: organization_path(@organization.id))

    assert_selector "h1", text: @organization.name

    click_on "Organizations"
  end

  test "should not see other account's organizations" do
    visit organizations_url

    # Can't see organization belonging to OSSAA account
    assert_no_text "Lincoln High School"
  end

  test "should not allow director to create" do
    log_in_as(users(:demo_director_a))
    visit organizations_url
    assert_no_text "New Organization"

    visit new_organization_url
    assert_text "You do not have permission to create organizations."
  end
end
