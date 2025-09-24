require "application_system_test_case"

class AccountSwitchingTest < ApplicationSystemTestCase
  setup do
    @sys_admin = users(:sys_admin_a)
    @demo_account = accounts(:demo)
    @customer_account = accounts(:customer)
    log_in_as(@sys_admin)
  end

  test "sysadmin can see account switcher in profile dropdown" do
    visit root_path

    # Click on profile dropdown
    click_on "#{@sys_admin.first_name} #{@sys_admin.last_name}"

    # Should see account switcher with "All Accounts" selected
    assert_selector "select[name='account_id']"
    assert_text "Account Context"
    assert_selector "option[value=''][selected]", text: "All Accounts"
  end

  test "sysadmin can switch to specific account" do
    visit users_path

    # Initially sysadmin should be in "All Accounts" mode
    # They might see users from any account (could be paginated)
    assert_text "Users"

    # Click on profile dropdown and switch to demo account
    click_on "#{@sys_admin.first_name} #{@sys_admin.last_name}"
    select "Public Demo", from: "account_id"

    # Should see confirmation message
    assert_text "Switched to Public Demo"

    # Should now only see demo account users
    assert_text "@demo.org" # Should see demo users
    assert_no_text "@school.org" # Should not see customer users

    # Title should reflect selected account
    assert_text "Public Demo Contest HQ"
  end

  test "sysadmin can switch back to all accounts" do
    # First switch to a specific account
    visit root_path
    click_on "#{@sys_admin.first_name} #{@sys_admin.last_name}"
    select "Public Demo", from: "account_id"
    assert_text "Switched to Public Demo"

    # Now switch back to all accounts
    click_on "#{@sys_admin.first_name} #{@sys_admin.last_name}"
    select "All Accounts", from: "account_id"

    # Should see confirmation message
    assert_text "Switched to all accounts view"

    # Should see users from all accounts again
    visit users_path
    # After switching back to all accounts, they should see the users list
    assert_text "Users"
  end

  test "regular user should not see account switcher" do
    log_in_as(users(:demo_admin_a))
    visit root_path

    # Click on profile dropdown
    click_on "#{users(:demo_admin_a).first_name} #{users(:demo_admin_a).last_name}"

    # Should not see account switcher
    assert_no_text "Account Context"
    assert_no_selector "select[name='account_id']"
  end

  test "account scoping works correctly when account is selected" do
    # Switch to demo account
    visit root_path
    click_on "#{@sys_admin.first_name} #{@sys_admin.last_name}"
    select "Public Demo", from: "account_id"

    # Visit different pages and ensure only demo account data is shown
    visit users_path
    assert_text users(:demo_director_a).email
    assert_no_text users(:customer_director_a).email

    # The account scoping should persist across requests
    visit root_path
    visit users_path
    assert_text users(:demo_director_a).email
    assert_no_text users(:customer_director_a).email
  end
end
