# TODO: only manager can generate or reset schedule
# TODO: all users can view schedule

require "application_system_test_case"

class SchedulingTest < ApplicationSystemTestCase
  setup do
    log_in_as(users(:demo_manager_a))
    @contest = contests(:demo_contest_a)
  end

  test "generate schedule button not visible if no setup" do
    visit schedule_url(@contest.schedules.first.id)
    assert_selector "h1", text: "Schedule"
    assert_no_selector "button", text: "Generate contest schedule"
  end
end
