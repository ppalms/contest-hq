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

    # Register for Regional Orchestra (demo_contest_b) which has prescribed music for Class A
    # Find the contest by name and click its Register button
    # Wait for contests to load
    assert_selector "li", text: /Regional Orchestra/, wait: 5
    contest_item = find("li", text: /Regional Orchestra/)
    within contest_item do
      click_on "Register"
    end

    assert_text "New Contest Entry"
    assert_text "Symphonic Orchestra"
    click_on "Continue"
    assert_text "Contest entry was successfully created"

    # Get the created entry for later assertions
    entry = ContestEntry.last

    click_on "Add Prescribed Music"

    # Search for and select Symphony No. 5
    fill_in "search", with: "Symphony"
    click_on "Search"

    # Verify only prescribed music from demo account is shown (tenant isolation)
    assert_text "Symphony No. 5", wait: 5

    # Click the Select button in the row with Symphony No. 5
    row = find("tr", text: "Symphony No. 5")
    within row do
      click_on "Select"
    end

    # Verify prescribed music appears with correct badges
    assert_text "Music selection added successfully"
    assert_text "Prescribed"
    assert_text "Symphony No. 5"

    # Add a custom piece
    click_on "Add Custom Music"

    fill_in "Title", with: "Custom Piece"
    fill_in "Composer", with: "Custom Composer"
    click_on "Add Music Selection"

    # Verify we're back on the show page with both pieces
    assert_text "Music selection added successfully"
    assert_text "Music Selections"
    assert_text "Symphony No. 5"
    assert_text "Prescribed"
    assert_text "Custom Piece"

    # Verify tenant isolation - prescribed music belongs to correct account
    entry.reload
    prescribed = entry.prescribed_selection
    assert_not_nil prescribed, "Should have prescribed music"
    assert_equal @new_director.account_id, prescribed.account_id, "Prescribed music should belong to director's account"
    assert_equal @new_director.account_id, prescribed.prescribed_music.account_id, "Prescribed music reference should belong to director's account"
    assert_equal "Symphony No. 5", prescribed.title

    # Verify prescribed music matches contest season and school class
    contest = entry.contest
    assert_equal contest.season_id, prescribed.prescribed_music.season_id, "Prescribed music should match contest season"
    assert_equal assigned_school.school_class_id, prescribed.prescribed_music.school_class_id, "Prescribed music should match school class"
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

    # Add Kennedy High School (demo_school_a, Class A) to the director
    within("table") do
      # Find the row with Kennedy High School and check its checkbox
      row = find("tr", text: "Kennedy High School")
      within(row) do
        find("input[type='checkbox']").check
      end
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
