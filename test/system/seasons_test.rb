require "application_system_test_case"

class SeasonsTest < ApplicationSystemTestCase
  def setup
    @admin_user = users(:demo_admin_a)
    sign_in_as(@admin_user)
  end

  test "admin can manage seasons" do
    visit seasons_path

    assert_text "Contest Seasons"
    assert_link "New Season"

    # Create a new season
    click_link "New Season"
    assert_text "New Season"

    fill_in "Name", with: "2026"
    click_button "Create Season"

    assert_text "Season was successfully created"
    assert_text "2026"
  end

  test "contest index shows season filter" do
    visit contests_path

    assert_text "Season:"
    assert_select "season_id"
  end

  test "non-admin cannot access seasons" do
    # Sign out admin and sign in as director
    find_button("Sign out", match: :first).click
    sign_in_as(users(:demo_director_a))

    visit seasons_path
    assert_current_path root_path
  end

  private

  def sign_in_as(user)
    visit sign_in_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "Secret1*3*5*"
    click_button "Sign in"
  end
end