require "application_system_test_case"

class SeasonsTest < ApplicationSystemTestCase
  def setup
    @admin_user = create(:user, :account_admin)
    log_in_as(@admin_user)
  end

  test "admin can manage seasons" do
    visit seasons_path

    assert_text "Contest Seasons"
    assert_link "New Season"

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
  end

  test "non-admin cannot access seasons" do
    find_button(@admin_user.last_name, match: :first).click
    find_button("Sign out", match: :first).click

    log_in_as(create(:user, :director, account: @admin_user.account))

    visit seasons_path
    assert_current_path root_path
  end
end
