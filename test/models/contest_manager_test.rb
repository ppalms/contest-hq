require "test_helper"

class ContestManagerTest < ActiveSupport::TestCase
  setup do
    @demo_contest = contests(:demo_contest_a)
    @demo_manager = users(:demo_manager_a)
    @demo_admin = users(:demo_admin_a)
    @demo_director = users(:demo_director_a)
  end

  test "valid with manager role user" do
    set_current_user(@demo_admin)
    # Use a manager not already assigned to this contest
    other_manager = users(:demo_manager_b)
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
    # Use a manager not already assigned to this contest
    other_manager = users(:demo_manager_b)
    
    # First assignment should work
    contest_manager1 = ContestManager.new(contest: @demo_contest, user: other_manager)
    assert contest_manager1.save

    # Second assignment of same user to same contest should fail
    contest_manager2 = ContestManager.new(contest: @demo_contest, user: other_manager)
    assert_not contest_manager2.valid?
    assert_includes contest_manager2.errors[:contest_id], "has already been taken"
  end
end
