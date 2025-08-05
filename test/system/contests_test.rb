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
    fill_in "Start date", with: @contest.contest_start
    fill_in "End date", with: @contest.contest_end
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

    assert_text "Start Date\nTBD"
    assert_text "End Date\nTBD"
  end

  test "should prevent saving end date before start date" do
    visit contests_url
    click_on "New Contest"

    fill_in "Name", with: "Contest With Backward Dates"
    fill_in "Start date", with: Date.new(2024, 10, 8)
    fill_in "End date", with: Date.new(2024, 10, 6)
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

  test "director sees register button for eligible contest" do
    # Director with a level A group
    log_in_as(users(:demo_director_a))

    # Contest allows level A groups
    elibile_contest = contests(:demo_contest_b)
    visit contest_url elibile_contest.id
    assert_text "Register"
  end

  # TODO: fix
  # test "director does not see register button for ineligible contest" do
  #   # Director with a level A group
  #   log_in_as(users(:demo_director_a))

  #   # Contest does not allow level A groups
  #   ineligible_contest = contests(:demo_contest_c)
  #   visit contest_url ineligible_contest.id
  #   assert_no_text "Register"
  # end

  test "director cannot view contest entry index" do
    log_in_as(users(:demo_director_a))
    visit contest_entries_url(contests(:demo_contest_b))
    assert_text "Contests"
    assert_no_text "Contest Entries"
  end

  test "director only sees their own entries" do
    log_in_as(users(:demo_director_a))
    visit contest_url(contests(:demo_contest_a))
    assert_text "Ironfoundersson"
    assert_text "Wind Ensemble"
  end

  test "manager list is visible on contest detail view for all users" do
    # Test as Account Admin
    log_in_as(users(:demo_admin_a))
    visit contest_url(contests(:demo_contest_a))
    assert_text "Managers"
    assert_text "Nobby Nobbs"

    # Test as Director
    log_in_as(users(:demo_director_a))
    visit contest_url(contests(:demo_contest_a))
    assert_text "Managers"
    assert_text "Nobby Nobbs"

    # Test as Manager
    log_in_as(users(:demo_manager_a))
    visit contest_url(contests(:demo_contest_a))
    assert_text "Managers"
    assert_text "Nobby Nobbs"
  end

  test "only account admins can add or remove contest managers" do
    # Account Admin can see Manage Managers link
    log_in_as(users(:demo_admin_a))
    visit contest_url(contests(:demo_contest_a))
    assert_text "Assign Managers"

    # Director cannot see Manage Managers link
    log_in_as(users(:demo_director_a))
    visit contest_url(contests(:demo_contest_a))
    assert_no_text "Assign Managers"

    # Manager cannot see Manage Managers link
    log_in_as(users(:demo_manager_a))
    visit contest_url(contests(:demo_contest_a))
    assert_no_text "Assign Managers"

    # Director cannot access managers controller directly
    log_in_as(users(:demo_director_a))
    visit contest_managers_path(contests(:demo_contest_a))
    assert_text "Contests" # Should redirect to home/contests due to authorization failure

    # Manager cannot access managers controller directly
    log_in_as(users(:demo_manager_a))
    visit contest_managers_path(contests(:demo_contest_a))
    assert_text "Contests" # Should redirect to home/contests due to authorization failure
  end
end
