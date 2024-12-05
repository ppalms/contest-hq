require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get sign_up_url
    assert_response :success
  end

  # TODO: implement self-sign-up
  # test "should sign up" do
  #   assert_difference("User.count") do
  #     post sign_up_url, params: {
  #       first_name: "Jack",
  #       last_name: "Palmer",
  #       email: "user_1@ppalmer.dev",
  #       password: "Secret1*3*5*",
  #       password_confirmation: "Secret1*3*5*",
  #       time_zone: "America/Chicago"
  #     }
  #   end

  #   assert_redirected_to root_url
  # end
end
