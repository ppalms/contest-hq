require "application_system_test_case"

class SchedulingTest < ApplicationSystemTestCase
  setup do
    @admin = create(:user, :account_admin)
    @manager = create(:user, :manager, account: @admin.account)
    @contest = create(:contest, account: @admin.account)
    create(:schedule, contest: @contest, account: @admin.account)
    create(:contest_manager, contest: @contest, user: @manager, account: @admin.account)
    log_in_as(@manager)
  end

  test "generate schedule button not visible if no setup" do
    visit schedule_url(@contest.schedules.first.id)
    assert_selector "h1", text: "Schedule"
    assert_no_selector "button", text: "Generate contest schedule"
  end
end
