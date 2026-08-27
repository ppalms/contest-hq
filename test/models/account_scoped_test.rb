require "test_helper"

class AccountScopedTest < ActiveSupport::TestCase
  setup do
    @sysadmin = users(:sys_admin_a)
    @demo_admin = users(:demo_admin_a)
    @demo_account = accounts(:demo)
    @customer_account = accounts(:customer)
    Current.reset
  end

  teardown do
    Current.reset
  end

  test "sysadmin sees all users when no account selected" do
    set_current_user(@sysadmin)
    Current.selected_account = nil

    users = User.all
    assert users.exists?(account: @demo_account)
    assert users.exists?(account: @customer_account)
  end

  test "sysadmin sees only selected account users when account is selected" do
    set_current_user(@sysadmin)
    Current.selected_account = @demo_account

    users = User.all
    assert users.exists?(account: @demo_account)
    assert_not users.exists?(account: @customer_account)
  end

  test "regular user only sees their account users regardless of selected_account" do
    set_current_user(@demo_admin)
    Current.selected_account = @customer_account  # This should be ignored

    users = User.all
    assert users.exists?(account: @demo_account)
    assert_not users.exists?(account: @customer_account)
  end

  test "account scoped models work with selected account" do
    set_current_user(@sysadmin)
    Current.selected_account = @demo_account

    # Test with a model that includes AccountScoped
    contest_managers = ContestManager.all
    # Should only see contest managers from the selected account
    if contest_managers.any?
      contest_managers.each do |cm|
        assert_equal @demo_account, cm.account
      end
    end
  end

  test "scoped queries return nothing without Current context" do
    Current.reset

    assert_empty User.all
    assert_empty Contest.all
    assert_empty Season.all
  end

  test "regular user creating a record without account uses their own account" do
    set_current_user(@demo_admin)

    season = Season.create!(name: "Test Season")
    assert_equal @demo_account, season.account
  end

  test "sysadmin creating a record without account uses selected account" do
    set_current_user(@sysadmin)
    Current.selected_account = @demo_account

    season = Season.create!(name: "Test Season")
    assert_equal @demo_account, season.account
  end

  test "rejects belongs_to association from another account" do
    set_current_user(@demo_admin)
    customer_contest = Contest.unscoped { contests(:customer_contest_a) }

    entry = ContestEntry.new(
      contest: customer_contest,
      large_ensemble: large_ensembles(:demo_school_a_ensemble_a),
      user: @demo_admin
    )

    assert_not entry.valid?
    assert entry.errors[:contest].any?
  end

  test "allows belongs_to associations from the same account" do
    set_current_user(@demo_admin)

    entry = ContestEntry.new(
      contest: contests(:demo_contest_a),
      large_ensemble: large_ensembles(:demo_school_a_ensemble_a),
      user: @demo_admin
    )

    assert entry.valid?
    assert_empty entry.errors[:contest]
    assert_empty entry.errors[:large_ensemble]
    assert_empty entry.errors[:user]
  end
end
