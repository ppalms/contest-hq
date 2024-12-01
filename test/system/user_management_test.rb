require "application_system_test_case"

class UserManagementTest < ApplicationSystemTestCase
  setup do
    log_in_as(users(:sys_admin))
  end

  test "sysadmin role should display sysadmin dashboard" do
    visit root_url

    assert_text "New Accounts"
    assert_text "Recent Sessions"
  end

  test "tenant admin role should display tenant admin dashboard" do
    log_in_as(users(:tenant_admin))
    visit root_url

    assert_text "Users"
  end

  test "director role should display director dashboard" do
    log_in_as(users(:director))
    visit root_url

    assert_text "My Entries"
    assert_text "Contest Calendar"
  end

  test "should allow multiple roles" do
    visit edit_user_url(users(:director))

    check "Judge"
    click_on "Update user"

    assert_text "User updated successfully"
    assert users(:director).reload.judge?
  end

  test "should allow sysadmin to invite tenant admin" do
    visit new_invitation_url

    fill_in "First name", with: "New"
    fill_in "Last name", with: "Tenant Admin"
    fill_in "Email", with: "new_tenant_admin@ppalmer.dev"
    select "Central Time (US & Canada)", from: "Time zone"
    check "TenantAdmin"
    click_on "Send invitation"

    assert_text "An invitation email has been sent to new_tenant_admin@ppalmer.dev"
    new_user = User.find_by(email: "new_tenant_admin@ppalmer.dev")
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

  test "should allow tenant admin to invite director" do
    log_in_as(users(:tenant_admin))
    visit new_invitation_url
    fill_in "First name", with: "New"
    fill_in "Last name", with: "Director"
    fill_in "Email", with: "new_director@ppalmer.dev"
    select "Central Time (US & Canada)", from: "Time zone"
    check "Director"
    assert_no_text "TenantAdmin"
    click_on "Send invitation"

    assert_text "An invitation email has been sent to new_director@ppalmer.dev"
    new_user = User.find_by(email: "new_director@ppalmer.dev")
    signed_id = new_user.generate_token_for(:password_reset)
    visit edit_identity_password_reset_url(sid: signed_id)

    assert_text "Reset your password"
    fill_in "New password", with: "Secret1*3*5*"
    fill_in "Confirm new password", with: "Secret1*3*5*"
    click_on "Save changes"
    assert_text "Your password was reset successfully"

    log_in_as(new_user)
    assert_text "My Entries"
    assert_text "Contest Calendar"
  end
end
