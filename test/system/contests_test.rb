require "application_system_test_case"

class ContestsTest < ApplicationSystemTestCase
  setup do
    @admin = create(:user, :account_admin)
    set_current_user(@admin)
    @director = create(:user, :director, account: @admin.account)
    @manager = create(:user, :manager, account: @admin.account)
    @season = create(:season, account: @admin.account, name: "2026", ordinal: 100)
    @contest = create(:contest, account: @admin.account, season: @season)
    @contest_b = create(:contest, account: @admin.account, season: @season)
    @customer_contest = create(:contest, account: create(:account, name: "Customer"))

    create(:school_class, account: @admin.account, name: "1-A")
    create(:school_class, account: @admin.account, name: "2-A")

    create(:large_ensemble, account: @admin.account)

    create(:contest_manager, contest: @contest, user: @manager, account: @admin.account)

    log_in_as(@admin)
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

    assert_selector "form.wide-form"

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

    assert_no_text @customer_contest.name
  end

  test "directors do not see new contest button" do
    log_in_as(@director)
    visit contests_url
    assert_no_text "New Contest"
  end

  test "director sees register button for eligible contest" do
    log_in_as(@director)

    visit contest_url @contest_b.id
    assert_text "Register"
  end

  # TODO: fix
  # test "director does not see register button for ineligible contest" do
  #   log_in_as(@director)
  #   ineligible_contest = @contest
  #   visit contest_url ineligible_contest.id
  #   assert_no_text "Register"
  # end

  test "director cannot view contest entry index" do
    log_in_as(@director)
    visit contest_entries_url(@contest_b)
    assert_text "Contests"
    assert_no_text "Contest Entries"
  end

  test "director only sees their own entries" do
    director = create(:user, :director, account: @admin.account, first_name: "Carrot", last_name: "Ironfoundersson")
    ensemble = create(:large_ensemble, account: @admin.account, name: "Wind Ensemble")
    create(:contest_entry, contest: @contest, user: director, large_ensemble: ensemble, account: @admin.account)

    log_in_as(director)
    visit contest_url(@contest)
    assert_text "Ironfoundersson"
    assert_text "Wind Ensemble"
  end

  test "manager list is visible on contest detail view for all users" do
    manager = create(:user, :manager, account: @admin.account, first_name: "Nobby", last_name: "Nobbs")
    create(:contest_manager, contest: @contest, user: manager, account: @admin.account)

    log_in_as(@admin)
    visit contest_url(@contest)
    assert_text "Managers"
    assert_text "Nobby Nobbs"

    log_in_as(@director)
    visit contest_url(@contest)
    assert_text "Managers"
    assert_text "Nobby Nobbs"

    log_in_as(@manager)
    visit contest_url(@contest)
    assert_text "Managers"
    assert_text "Nobby Nobbs"
  end

  test "only account admins can add or remove contest managers" do
    log_in_as(@admin)
    visit contest_url(@contest)
    assert_text "Assign Managers"

    log_in_as(@director)
    visit contest_url(@contest)
    assert_no_text "Assign Managers"

    log_in_as(@manager)
    visit contest_url(@contest)
    assert_no_text "Assign Managers"

    log_in_as(@director)
    visit contest_managers_path(@contest)
    assert_text "Contests"

    log_in_as(@manager)
    visit contest_managers_path(@contest)
    assert_text "Contests"
  end
end
