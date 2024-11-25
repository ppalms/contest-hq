require "application_system_test_case"

class RegistrationsTest < ApplicationSystemTestCase
  setup do
    @user = User.new(
      first_name: "John",
      last_name: "Doe",
      email: "jdoe@school.org",
      password: "Secret1*3*5*"
    )
  end

  test "user role should default to director" do
    visit sign_up_url

    # TODO: get current time zone from the system
    # default_time_zone = "America/Chicago"
    # assert_equal default_time_zone, find_field("Time zone").value

    fill_in "First name", with: @user.first_name
    fill_in "Last name", with: @user.last_name
    fill_in "Email", with: @user.email
    fill_in "Password", with: @user.password
    fill_in "Password confirmation", with: @user.password
    click_on "Sign up"

    assert_text "Welcome! You have signed up successfully."
  end
end
