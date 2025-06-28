require "application_system_test_case"

class AccountsTest < ApplicationSystemTestCase
  setup do
    log_in_as(users(:sys_admin_a))
    @account = accounts(:ossaa)
  end

  test "visiting the index" do
    visit accounts_url
    assert_selector "h1", text: "Accounts"
  end

  test "should create account" do
    visit accounts_url
    click_on "New Account"

    fill_in "Name", with: "New Test Account"

    click_on "Create Account"

    assert_text "Account was successfully created"
    assert_text "New Test Account"
    click_on "Accounts"
  end

  test "should update Account" do
    visit account_url(@account)
    click_on "Edit", match: :first

    fill_in "Name", with: "New Account Name"

    click_on "Update Account"

    assert_text "Account was successfully updated"
    assert_text "New Account Name"
    click_on "Accounts"
  end
end
