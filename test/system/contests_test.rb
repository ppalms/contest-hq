require "application_system_test_case"

class ContestsTest < ApplicationSystemTestCase
  setup do
    log_in_as(users(:sys_admin))
    @contest = contests(:coda)
  end

  test "visiting the index" do
    visit contests_url
    assert_selector "h1", text: "Contests"
  end

  test "should create contest" do
    visit contests_url
    click_on "New contest"

    fill_in "Name", with: @contest.name
    fill_in "Contest start", with: @contest.contest_start
    fill_in "Contest end", with: @contest.contest_end
    click_on "Create Contest"

    assert_text "Contest was successfully created"
    click_on "Back"
  end

  test "should update contest" do
    visit contest_url(@contest)
    click_on "Edit", match: :first

    fill_in "Name", with: @contest.name
    click_on "Update Contest"

    assert_text "Contest was successfully updated"
    click_on "Back"
  end

  test "should delete contest" do
    visit contest_url(@contest)
    click_on "Delete", match: :first

    accept_confirm

    assert_text "Contest was successfully deleted"
  end

  test "showing a contest" do
    visit contests_url
    click_link @contest.name

    assert_selector "h1", text: @contest.name
  end

  test "should prevent saving end date before start date" do
    visit contests_url
    click_on "New contest"

    fill_in "Name", with: @contest.name
    fill_in "Contest start", with: Date.new(2024, 10, 8)
    fill_in "Contest end", with: Date.new(2024, 10, 6)
    click_on "Create Contest"

    assert_text "date must be after start date"
  end
end
