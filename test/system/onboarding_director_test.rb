require "application_system_test_case"

class OnboardingDirectorTest < ApplicationSystemTestCase
  include LargeEnsemblesHelper

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

    # Select the first available school (whichever was assigned during invitation)
    @new_director.reload
    assigned_school = @new_director.schools.first
    assert_text assigned_school.name if assigned_school

    select display_name_with_abbreviation(performance_classes(:demo_performance_class_a)), from: :performance_class_id
    click_on "Create Large Ensemble"
    assert_text "Large ensemble was successfully created"

    assert_text "Contests"
    # Register for the first available contest
    click_on "Register", match: :first

    assert_text "New Contest Entry"
    assert_text "Symphonic Orchestra"
    click_on "Continue"
    assert_text "Contest entry was successfully created"

    click_on "Add Music"

    within all("[data-slot-type='custom']").first do
      click_on "Add"
    end

    fill_in "Title", with: "Symphony No. 5"
    fill_in "Composer", with: "Beethoven"
    click_on "Add to List"

    assert_text "New"

    find("input[value='Save']").click

    assert_text "Music Selections"
    assert_text "1/3 pieces selected"
    assert_text "Symphony No. 5"
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
    assert_no_text "AccountAdmin"
    click_on "Send Invitation"

    # Now assign schools to the newly created user
    assert_text "User #{email} has been created"

    # Add a school to the director
    within("table") do
      first("input[type='checkbox']").check
    end
    click_on "Add Selected"

    assert_text "school(s) added successfully"

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
