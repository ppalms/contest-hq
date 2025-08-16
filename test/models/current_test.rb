require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  setup do
    @user = users(:sys_admin_a)
    @demo_account = accounts(:demo)
    @customer_account = accounts(:customer)
    Current.reset
  end

  teardown do
    Current.reset
  end

  test "effective_account returns selected_account when set" do
    Current.account = @user.account
    Current.selected_account = @demo_account
    
    assert_equal @demo_account, Current.effective_account
  end

  test "effective_account returns account when selected_account is nil" do
    Current.account = @user.account
    Current.selected_account = nil
    
    assert_equal @user.account, Current.effective_account
  end

  test "effective_account returns nil when both accounts are nil" do
    Current.account = nil
    Current.selected_account = nil
    
    assert_nil Current.effective_account
  end

  test "selected_account can be set and retrieved" do
    Current.selected_account = @demo_account
    
    assert_equal @demo_account, Current.selected_account
  end
end