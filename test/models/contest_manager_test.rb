require "test_helper"

class ContestManagerTest < ActiveSupport::TestCase
  setup do
    @demo_contest = create(:contest)
    @demo_manager = create(:user, :manager, account: @demo_contest.account)
    @demo_admin = create(:user, :account_admin, account: @demo_contest.account)
    @demo_director = create(:user, :director, account: @demo_contest.account)
  end

  test "valid with manager role user" do
    set_current_user(@demo_admin)
    other_manager = create(:user, :manager, account: @demo_contest.account)
    contest_manager = ContestManager.new(contest: @demo_contest, user: other_manager)
    assert contest_manager.valid?
  end

  test "invalid with non-manager role user" do
    set_current_user(@demo_admin)
    contest_manager = ContestManager.new(contest: @demo_contest, user: @demo_admin)
    assert_not contest_manager.valid?
    assert_includes contest_manager.errors[:user], "must have the Manager role"
  end

  test "invalid with director role user" do
    set_current_user(@demo_admin)
    contest_manager = ContestManager.new(contest: @demo_contest, user: @demo_director)
    assert_not contest_manager.valid?
    assert_includes contest_manager.errors[:user], "must have the Manager role"
  end

  test "must be unique per contest and user" do
    set_current_user(@demo_admin)
    other_manager = create(:user, :manager, account: @demo_contest.account)

    contest_manager1 = ContestManager.new(contest: @demo_contest, user: other_manager)
    assert contest_manager1.save

    contest_manager2 = ContestManager.new(contest: @demo_contest, user: other_manager)
    assert_not contest_manager2.valid?
    assert_includes contest_manager2.errors[:contest_id], "has already been taken"
  end
end
