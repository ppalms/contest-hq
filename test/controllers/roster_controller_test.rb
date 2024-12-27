require "test_helper"

class RosterControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:sys_admin_a)
  end

  test "should get index" do
    sign_in_as @user
    get roster_url
    assert_response :success
  end
end
