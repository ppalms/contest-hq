require "test_helper"

class ContestSchedulerTest < ActiveSupport::TestCase
  test "should belong to contest and user" do
    contest_scheduler = contest_schedulers(:scheduler_a_contest_a)
    assert_not_nil contest_scheduler.contest
    assert_not_nil contest_scheduler.user
  end

  test "should validate uniqueness of contest_id scoped to user_id" do
    existing = contest_schedulers(:scheduler_a_contest_a)
    duplicate = ContestScheduler.new(
      contest: existing.contest,
      user: existing.user,
      account: existing.account
    )
    
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:contest_id], "has already been taken"
  end
end