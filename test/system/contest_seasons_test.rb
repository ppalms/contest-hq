require "application_system_test_case"

class ContestSeasonsTest < ApplicationSystemTestCase
  setup do
    log_in_as(users(:demo_admin_a))
    @contest_season = contest_seasons(:demo_season_a)
  end

  test "visiting the index" do
    visit contest_seasons_url
    assert_selector "h1", text: "Contest Seasons"
  end

  test "should create contest season" do
    visit contest_seasons_url
    click_on "New Contest Season"

    fill_in "Name", with: "2025"
    click_on "Create Contest Season"

    assert_text "Contest season was successfully created"
    assert_text "2025"
  end

  test "should update contest season" do
    visit contest_season_url(@contest_season)
    click_on "Edit", match: :first

    fill_in "Name", with: "Updated Season Name"
    click_on "Update Contest Season"

    assert_text "Contest season was successfully updated"
    assert_text "Updated Season Name"
  end

  test "should delete contest season" do
    visit contest_season_url(@contest_season)
    click_on "Delete", match: :first

    accept_confirm

    assert_text "Contest season was successfully deleted"
    assert_no_text @contest_season.name
  end

  test "should show contest season with associated contests" do
    visit contest_season_url(@contest_season)
    
    assert_selector "h1", text: @contest_season.name
    assert_selector "h2", text: "Contests"
    
    # Should show contests that belong to this season
    @contest_season.contests.each do |contest|
      assert_text contest.name
    end
  end

  test "contest season name cannot be empty" do
    visit contest_seasons_url
    click_on "New Contest Season"

    fill_in "Name", with: ""
    click_on "Create Contest Season"

    assert_text "Name can't be blank"
  end

  test "contest season name must be unique per account" do
    existing_season = @contest_season
    
    visit contest_seasons_url
    click_on "New Contest Season"

    fill_in "Name", with: existing_season.name
    click_on "Create Contest Season"

    assert_text "Name has already been taken"
  end

  test "contest season defaults to current year" do
    visit contest_seasons_url
    click_on "New Contest Season"

    # The form should have a default value for current year
    name_field = find_field("Name")
    current_year = Date.current.year.to_s
    
    # Check if the field has the current year as default value
    assert_equal current_year, name_field.value
  end

  test "directors cannot access contest seasons" do
    log_in_as(users(:demo_director_a))
    
    visit contest_seasons_url
    
    # Should be redirected or see unauthorized message
    assert_no_text "Contest Seasons"
    assert_current_path(root_path) || assert_text("not authorized") || assert_text("You must be")
  end

  test "contest seasons navigation only visible to admins" do
    # Admin should see the link
    visit root_path
    click_button class: "hamburger"
    assert_text "Contest Seasons"
    
    # Director should not see the link
    log_in_as(users(:demo_director_a))
    visit root_path
    click_button class: "hamburger"
    assert_no_text "Contest Seasons"
  end
end
