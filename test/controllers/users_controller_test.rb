require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sysadmin = create(:user, :sys_admin)
    @demo_admin = create(:user, :account_admin)
    @customer_admin = create(:user, :account_admin)
    @customer_director = create(:user, :director, account: @customer_admin.account)
  end

  test "sysadmin should access show user from any account" do
    sign_in_as @sysadmin

    get user_url(@customer_director)
    assert_response :success
  end

  test "sysadmin should access edit user from any account" do
    sign_in_as @sysadmin

    get edit_user_url(@customer_director)
    assert_response :success
  end

  test "sysadmin should update user from any account" do
    sign_in_as @sysadmin

    patch user_url(@customer_director), params: {
      user: {
        first_name: "Updated",
        last_name: "Name"
      }
    }
    assert_redirected_to user_path(@customer_director)
    assert_equal "User updated successfully.", flash[:notice]
  end

  test "account admin should not access show user from different account" do
    sign_in_as @demo_admin

    get user_url(@customer_director)
    assert_response :not_found
  end

  test "account admin should not access edit user from different account" do
    sign_in_as @demo_admin

    get edit_user_url(@customer_director)
    assert_response :not_found
  end

  test "account admin should not update user from different account" do
    sign_in_as @demo_admin

    patch user_url(@customer_director), params: {
      user: {
        first_name: "Updated",
        last_name: "Name"
      }
    }
    assert_response :not_found
  end
end
