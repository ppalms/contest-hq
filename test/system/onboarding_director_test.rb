require "application_system_test_case"

class OnboardingDirectorTest < ApplicationSystemTestCase
  setup do
    invite_new_director("peggy@school.org")
  end

  test "should walk director through large ensemble registration" do
    visit root_url

    assert_text "Set up your roster to register for contests"
    click_on "Get Started"

    assert_text "Roster"
    click_on "Large Ensembles"

    assert_text "No large ensembles found"
    click_on "New Large Ensemble"

    fill_in "Name", with: "Symphonic Orchestra"
    assert_text schools(:demo_school_a).name
    select performance_classes(:demo_performance_class_a).name, from: :performance_class_id
    click_on "Create Large Ensemble"
    assert_text "Large ensemble was successfully created"

    assert_text "Contests"
    assert_no_text contests(:demo_contest_c).name
    click_on "Register", match: :first

    assert_text "New Contest Entry"
    assert_text "Symphonic Orchestra"
    click_on "Continue"
    assert_text "Contest entry was successfully created"

    click_on "Add Music Selection"
    assert_text "Add Music Selection"
    fill_in "Title", with: "Symphony No. 5"
    fill_in "Composer", with: "Beethoven"
    click_on "Save"
    assert_text "Music selection added to contest entry"
  end

  private

  def invite_new_director(email)
    log_in_as(users(:demo_admin_a))
    visit new_invitation_url

    fill_in "First name", with: "Nobby"
    fill_in "Last name", with: "Nobbs"
    fill_in "Email", with: email
    select "Central Time (US & Canada)", from: "Time zone"
    check "Director"
    select schools(:demo_school_a).name, from: "School"
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
