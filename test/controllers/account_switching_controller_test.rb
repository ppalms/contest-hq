require "test_helper"

class AccountSwitchingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sys_admin = users(:sys_admin_a)
    @demo_account = accounts(:demo)
    @customer_account = accounts(:customer)
    @demo_admin = users(:demo_admin_a)
  end

  test "sysadmin can switch to specific account" do
    sign_in_as @sys_admin

    post switch_account_path, params: { account_id: @demo_account.id }

    assert_redirected_to root_path
    follow_redirect!
    assert_equal "Switched to Public Demo", flash[:notice]
    assert_equal @demo_account.id, session[:selected_account_id]
  end

  test "sysadmin can switch to all accounts view" do
    sign_in_as @sys_admin

    # First set a selected account
    post switch_account_path, params: { account_id: @demo_account.id }

    # Then switch to all accounts
    post switch_account_path, params: { account_id: "" }

    assert_redirected_to root_path
    follow_redirect!
    assert_equal "Switched to all accounts view", flash[:notice]
    assert_nil session[:selected_account_id]
  end

  test "sysadmin can clear account selection" do
    sign_in_as @sys_admin

    # First set a selected account
    post switch_account_path, params: { account_id: @demo_account.id }
    assert_equal @demo_account.id, session[:selected_account_id]

    # Clear the selection
    delete switch_account_path

    assert_redirected_to root_path
    follow_redirect!
    assert_equal "Switched to all accounts view", flash[:notice]
    assert_nil session[:selected_account_id]
  end

  test "non-sysadmin cannot access account switching" do
    sign_in_as @demo_admin

    post switch_account_path, params: { account_id: @demo_account.id }
    assert_redirected_to root_path

    delete switch_account_path
    assert_redirected_to root_path
  end

  test "account switching preserves selected account in Current" do
    sign_in_as @sys_admin

    post switch_account_path, params: { account_id: @demo_account.id }

    # Make another request and verify Current.selected_account is set
    get root_path
    assert_equal @demo_account, Current.selected_account
  end
end
