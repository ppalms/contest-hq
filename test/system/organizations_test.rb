require "application_system_test_case"

class OrganizationsTest < ApplicationSystemTestCase
  setup do
    log_in_as(users(:tenant_admin))
    @organization = organizations(:five)
  end

  test "visiting the index" do
    visit organizations_url
    assert_selector "h1", text: "Organizations"
    assert_text "Washington High School"
    assert_text "Kennedy High School"
    assert_text "Memorial High School"
    assert_text "Central High School"
  end

  #  test "should create organization" do
  #    visit organizations_url
  #    click_on "New organization"
  #
  #    fill_in "Name", with: @organization.name
  #    fill_in "Organization Type", with: @organization.organization_type
  #    click_on "Create Organization"
  #
  #    assert_text "Organization was successfully created"
  #    click_on "Browse Organizations"
  #  end
  #
  #  test "should update organization" do
  #    visit organization_url(@organization)
  #    click_on "Edit", match: :first
  #
  #    fill_in "Name", with: @organization.name
  #    click_on "Update Organization"
  #
  #    assert_text "Organization was successfully updated"
  #    click_on "Browse Organizations"
  #  end
  #
  #  test "should delete organization" do
  #    visit organization_url(@organization)
  #    click_on "Delete", match: :first
  #
  #    accept_confirm
  #
  #    assert_text "Organization was successfully deleted"
  #  end

  #  test "showing an organization" do
  #    visit organizations_url
  #    click_link @organization.name
  #
  #    assert_selector "h1", text: @organization.name
  #  end

  test "should not see other account's organizations" do
    visit organizations_url

    # Can't see organization belonging to OSSAA account
    assert_no_text "Lincoln High School"
  end
end
