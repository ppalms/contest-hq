require "application_system_test_case"

class UserManagementTest < ApplicationSystemTestCase
  setup do
    log_in_as(users(:sys_admin_a))
  end

  test "sysadmin role should display sysadmin dashboard" do
    visit root_url

    assert_text "New Accounts"
    assert_text "Active Sessions"
  end

  test "account admin role should display account admin dashboard" do
    log_in_as(users(:demo_admin_a))
    visit root_url

    assert_text "Users"
  end

  test "director role should display director dashboard" do
    log_in_as(users(:demo_director_a))
    visit root_url

    assert_text "My Entries"
    assert_text "My Scores"
    assert_text "Contests"
  end

  test "should allow multiple roles" do
    log_in_as(users(:demo_admin_a))

    # Find a user with only Director role
    director = users(:demo_director_a)

    # Visit the edit page
    visit edit_user_url(director)

    # Verify Director role is already checked
    assert find_field("Director", visible: false).checked?

    # Verify Judge role is not checked initially
    assert_not find_field("Judge", visible: false).checked?

    # Check the Judge checkbox to add the role
    check "Judge"

    # Verify both roles are now checked in the UI
    assert find_field("Director", visible: false).checked?
    assert find_field("Judge", visible: false).checked?
  end

  test "should allow sys admin to invite account admin" do
    visit new_invitation_url

    fill_in "First name", with: "New Account"
    fill_in "Last name", with: "Admin"
    fill_in "Email", with: "admin@somewhere.org"
    select "Central Time (US & Canada)", from: "Time zone"
    check "AccountAdmin"
    click_on "Send Invitation"

    # User is created first, then we need to assign schools
    assert_text "User admin@somewhere.org has been created"

    # Select at least one school
    within("table") do
      first("input[type='checkbox']").check
    end
    click_on "Add Selected"

    assert_text "Invitation email has been sent to admin@somewhere.org"
    new_user = User.find_by(email: "admin@somewhere.org")
    signed_id = new_user.generate_token_for(:password_reset)
    visit edit_identity_password_reset_url(sid: signed_id)

    assert_text "Reset your password"
    fill_in "New password", with: "Secret1*3*5*"
    fill_in "Confirm new password", with: "Secret1*3*5*"
    click_on "Save changes"
    assert_text "Your password was reset successfully"

    log_in_as(new_user)
    assert_text "Users"
  end

  test "should allow account admin to invite director" do
    log_in_as(users(:demo_admin_a))
    visit new_invitation_url
    fill_in "First name", with: "New"
    fill_in "Last name", with: "Director"
    fill_in "Email", with: "director@somewhere.org"
    select "Central Time (US & Canada)", from: "Time zone"
    check "Director"
    click_on "Send Invitation"

    # User is created first, then we need to assign schools
    assert_text "User director@somewhere.org has been created"

    # Select at least one school
    within("table") do
      first("input[type='checkbox']").check
    end
    click_on "Add Selected"

    assert_text "Invitation email has been sent to director@somewhere.org"
    new_user = User.find_by(email: "director@somewhere.org")
    signed_id = new_user.generate_token_for(:password_reset)
    visit edit_identity_password_reset_url(sid: signed_id)

    assert_text "Reset your password"
    fill_in "New password", with: "Secret1*3*5*"
    fill_in "Confirm new password", with: "Secret1*3*5*"
    click_on "Save changes"
    assert_text "Your password was reset successfully"

    log_in_as(new_user)
    assert_text "Set up your roster to register for contests"
  end

  test "should not allow account admin to invite account admin" do
    log_in_as(users(:demo_admin_a))
    visit new_invitation_url
    assert_no_text "AccountAdmin"
  end

  test "should only see users from own account" do
    log_in_as(users(:demo_admin_a))
    assert_no_text users(:customer_director_a).email

    visit users_url
    assert_no_text users(:customer_director_a).email
  end

  test "should not see sys admin user in dashboard" do
    log_in_as(users(:demo_admin_a))
    assert_no_text users(:sys_admin_a).email
  end
end
