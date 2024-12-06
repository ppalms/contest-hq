require "application_system_test_case"

class OnboardingDirectorTest < ApplicationSystemTestCase
  setup do
    invite_new_director("peggy@school.org")
  end

  def teardown
    if @new_director
      @new_director.destroy
    end
  end

  test "should prompt director to create contest group" do
    visit root_url

    assert_text "Create a contest group to get started"

    click_on "Create a contest group"

    assert_text "New Contest Group"
  end

  # test "should prompt director to register for contest" do
  # end

  private

  def invite_new_director(email)
    log_in_as(users(:customer_admin_a))
    visit new_invitation_url

    fill_in "First name", with: "Peggy"
    fill_in "Last name", with: "Hill"
    fill_in "Email", with: email
    select "Central Time (US & Canada)", from: "Time zone"
    check "Director"
    select organizations(:customer_school_c).name, from: "Organization"
    assert_no_text "AccountAdmin"
    click_on "Send Invitation"
    assert_text "An invitation email has been sent to #{email}"

    @new_director = User.find_by(email: email)
    signed_id = @new_director.generate_token_for(:password_reset)
    visit edit_identity_password_reset_url(sid: signed_id)
    assert_text "Reset your password"
    fill_in "New password", with: "Secret1*3*5*"
    fill_in "Confirm new password", with: "Secret1*3*5*"
    click_on "Save changes"
    assert_text "Your password was reset successfully"
    log_in_as(@new_director)
  end
end
