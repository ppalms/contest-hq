require "application_system_test_case"

class LargeGroupsTest < ApplicationSystemTestCase
  setup do
    log_in_as(users(:demo_director_a))
    @large_group = large_groups(:demo_school_a_group_c)
  end

  test "should create large ensemble" do
    visit roster_large_groups_url
    click_on "New Large Ensemble"
    fill_in "Name", with: "Ultra Symphonic Band"
    select large_group_classes(:demo_group_class_a).name, from: :large_group_class_id
    select organizations(:demo_school_a).name, from: :organization_id
    click_on "Create Large Ensemble"

    assert_text "Large ensemble was successfully created"
    click_on "Large Ensembles"
    assert_text "Ultra Symphonic Band"
  end

  test "should update large ensemble" do
    visit roster_large_group_url(@large_group)
    click_on "Edit", match: :first

    fill_in "Name", with: "New Large Ensemble Name"
    click_on "Update Large Ensemble"

    assert_text "Large ensemble was successfully updated"
    click_on "Large Ensemble"
    assert_text "New Large Ensemble Name"
  end

  test "should delete large ensemble" do
    visit roster_large_group_url(@large_group)
    click_on "Delete", match: :first

    accept_confirm

    assert_text "Large ensemble was successfully deleted"
    assert_no_text @large_group.name
  end

  test "showing a large ensemble" do
    visit roster_large_groups_url
    click_on "View", match: :first

    assert_selector "h1", text: "Wind Ensemble"
  end

  test "should only see own large ensemble" do
    visit roster_large_groups_url

    # Other director's large ensemble
    assert_no_text "Concert Band"
  end
end
