require "application_system_test_case"

class OnboardingDirectorTest < ApplicationSystemTestCase
  setup do
    invite_new_director("newguy@ossaa.org")
    @contest_group = contest_groups(:ossaa_symphonic)
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

  test "should create contest group" do
    visit contest_groups_url
    click_on "Create Contest Group"
    fill_in "Name", with: @contest_group.name
    select "1-A", from: :contest_group_class_id
    select "Santa Fe High School", from: :organization_id
    click_on "Create Contest Group"

    assert_text "Contest group was successfully created"
    click_on "Browse Contest Groups"
    assert_text @contest_group.name
  end

  test "should update contest group" do
    visit contest_group_url(@contest_group)
    click_on "Edit", match: :first

    fill_in "Name", with: "New Contest Group Name"
    click_on "Update Contest Group"

    assert_text "Contest group was successfully updated"
    click_on "Browse Contest Groups"
    assert_text "New Contest Group Name"
  end

  test "should delete contest group" do
    visit contest_group_url(@contest_group)
    click_on "Delete", match: :first

    accept_confirm

    assert_text "Contest group was successfully deleted"
    assert_no_text @contest_group.name
  end

  test "showing a contest group" do
    log_in_as(users(:director))
    visit contest_groups_url
    click_on "View", match: :first

    assert_selector "h1", text: contest_groups(:contest_hq_cantina).name
  end

  test "should only see own contest groups" do
    visit contest_groups_url

    # Other director's contest group
    assert_no_text "Concert Band"
  end

  private

  def invite_new_director(email)
    log_in_as(users(:ossaa_tenant_admin_bob))
    visit new_invitation_url

    fill_in "First name", with: "New"
    fill_in "Last name", with: "Director"
    fill_in "Email", with: email
    select "Central Time (US & Canada)", from: "Time zone"
    check "Director"
    select "Santa Fe High School", from: "Organization"
    assert_no_text "TenantAdmin"
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
