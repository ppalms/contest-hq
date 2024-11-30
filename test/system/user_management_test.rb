require "application_system_test_case"

class UserManagementTest < ApplicationSystemTestCase
  setup do
    log_in_as(users(:sys_admin))
  end

  test "sysadmin role should display sysadmin dashboard" do
    visit root_url

    assert_text "New Accounts"
    assert_text "Recent Sessions"
  end

  test "adding tenant admin role should display tenant admin dashboard" do
    visit edit_user_url(users(:sys_admin))

    select "TenantAdmin", from: "Roles"
    click_on "Update User"

    visit root_url

    assert_text "Upcoming Contests"
    assert_text "New Users"
  end

  test "adding director role should display director dashboard" do
    visit edit_user_url(users(:sys_admin))

    select "Director", from: "Roles"
    click_on "Update User"

    visit root_url

    assert_text "My Entries"
    assert_text "Contest Calendar"
  end
end
