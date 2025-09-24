require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sysadmin = users(:sys_admin_a)
    @demo_admin = users(:demo_admin_a)
    @customer_admin = users(:customer_admin_a)
    @customer_director = users(:customer_director_a)
  end

  test "sysadmin should access show user from any account" do
    sign_in_as @sysadmin

    # Sysadmin should be able to view user from customer account
    get user_url(@customer_director)
    assert_response :success
  end

  test "sysadmin should access edit user from any account" do
    sign_in_as @sysadmin

    # Sysadmin should be able to edit user from customer account
    get edit_user_url(@customer_director)
    assert_response :success
  end

  test "sysadmin should update user from any account" do
    sign_in_as @sysadmin

    # Sysadmin should be able to update user from customer account
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

    # Demo account admin should not be able to view user from customer account
    get user_url(@customer_director)
    assert_response :not_found
  end

  test "account admin should not access edit user from different account" do
    sign_in_as @demo_admin

    # Demo account admin should not be able to edit user from customer account
    get edit_user_url(@customer_director)
    assert_response :not_found
  end

  test "account admin should not update user from different account" do
    sign_in_as @demo_admin

    # Demo account admin should not be able to update user from customer account
    patch user_url(@customer_director), params: {
      user: {
        first_name: "Updated",
        last_name: "Name"
      }
    }
    assert_response :not_found
  end
end
