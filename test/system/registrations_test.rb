require "application_system_test_case"

class RegistrationsTest < ApplicationSystemTestCase
  setup do
    @user = User.new(
      first_name: "Test",
      last_name: "User",
      email: "test-user@school.org",
      password: "Secret1*3*5*"
    )
  end

  #  test "should register new user" do
  #    visit sign_up_url
  #
  #    # TODO: get current time zone from the system
  #    # default_time_zone = "America/Chicago"
  #    # assert_equal default_time_zone, find_field("Time zone").value
  #
  #    fill_in "First name", with: @user.first_name
  #    fill_in "Last name", with: @user.last_name
  #    fill_in "Email", with: @user.email
  #    fill_in "Password", with: @user.password
  #    fill_in "Password confirmation", with: @user.password
  #    select "Central Time (US & Canada)", from: "Time zone"
  #
  #    click_on "Sign up"
  #
  #    assert_text "Welcome! You have signed up successfully."
  #  end
end
