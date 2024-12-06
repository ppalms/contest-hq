require "application_system_test_case"

class ContestGroupsTest < ApplicationSystemTestCase
  setup do
    log_in_as(users(:demo_director_a))
    @contest_group = contest_groups(:demo_school_a_group_a)
  end

  test "should create contest group" do
    visit contest_groups_url
    click_on "New Contest Group"
    fill_in "Name", with: "Ultra Symphonic Band"
    select contest_group_classes(:demo_group_class_a).name, from: :contest_group_class_id
    select organizations(:demo_school_a).name, from: :organization_id
    click_on "Create Contest Group"

    assert_text "Contest group was successfully created"
    click_on "Browse Contest Groups"
    assert_text "Ultra Symphonic Band"
  end

  test "should update contest group" do
    visit contest_group_url(@contest_group)
    click_on "Edit", match: :first

    fill_in "Name", with: "New Contest Group Name"
    click_on "Update Contest Group"

    assert_text "Contest group was successfully updated"
    click_on "Browse Contest Groups"
    assert_text "New Contest Group Name"
  end

  test "should delete contest group" do
    visit contest_group_url(@contest_group)
    click_on "Delete", match: :first

    accept_confirm

    assert_text "Contest group was successfully deleted"
    assert_no_text @contest_group.name
  end

  test "showing a contest group" do
    visit contest_groups_url
    click_on "View", match: :first

    assert_selector "h1", text: @contest_group.name
  end

  test "should only see own contest groups" do
    visit contest_groups_url

    # Other director's contest group
    assert_no_text "Concert Band"
  end
end
