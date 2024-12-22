require "application_system_test_case"

class ContestsTest < ApplicationSystemTestCase
  setup do
    log_in_as(users(:demo_admin_a))
    @contest = contests(:demo_contest_c)
  end

  test "visiting the index" do
    visit contests_url
    assert_selector "h1", text: "Contests"
  end

  test "should create contest" do
    visit contests_url
    click_on "New Contest"

    fill_in "Name", with: "New Demo Contest"
    check "1-A"
    check "2-A"
    fill_in "Contest start", with: @contest.contest_start
    fill_in "Contest end", with: @contest.contest_end
    click_on "Create Contest"

    assert_text "Contest was successfully created"
    click_on "Contests"
    assert_text "New Demo Contest"
  end

  test "should update contest" do
    visit contest_url(@contest)
    click_on "Edit", match: :first

    fill_in "Name", with: "New Demo Contest Name"
    click_on "Update Contest"

    assert_text "Contest was successfully updated"
    click_on "Contests"
    assert_text "New Demo Contest Name"
  end

  test "should delete contest" do
    visit contest_url(@contest)
    click_on "Delete", match: :first

    accept_confirm

    assert_text "Contest was successfully deleted"
    assert_no_text @contest.name
  end

  test "showing a contest" do
    visit contests_url
    click_link(href: contest_path(@contest.id))

    assert_selector "h1", text: @contest.name
  end

  test "allows saving without start and end dates" do
    visit contests_url
    click_on "New Contest"

    fill_in "Name", with: "Contest With TBD Dates"
    click_on "Create Contest"

    assert_text "Contest was successfully created"

    assert_text "Contest Start\nTBD"
    assert_text "Contest End\nTBD"
  end

  test "should prevent saving end date before start date" do
    visit contests_url
    click_on "New Contest"

    fill_in "Name", with: "Contest With Backward Dates"
    fill_in "Contest start", with: Date.new(2024, 10, 8)
    fill_in "Contest end", with: Date.new(2024, 10, 6)
    click_on "Create Contest"

    assert_text "date must be after start date"
  end

  test "should not see other account's contests" do
    visit contests_url

    assert_no_text contests(:customer_contest_a).name
  end

  test "directors do not see new contest button" do
    log_in_as(users(:demo_director_a))
    visit contests_url
    assert_no_text "New Contest"
  end
end
