require "test_helper"

class AccountScopedTest < ActiveSupport::TestCase
  setup do
    @sysadmin = create(:user, :sys_admin)
    @demo_admin = create(:user, :account_admin)
    @demo_account = @demo_admin.account
    @customer_account = create(:account)
    create(:user, :account_admin, account: @customer_account)
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
    Current.selected_account = @customer_account

    users = User.all
    assert users.exists?(account: @demo_account)
    assert_not users.exists?(account: @customer_account)
  end

  test "account scoped models work with selected account" do
    set_current_user(@sysadmin)
    Current.selected_account = @demo_account

    contest_manager = create(:contest_manager, account: @demo_account)

    contest_managers = ContestManager.all
    assert contest_managers.any?
    contest_managers.each do |cm|
      assert_equal @demo_account, cm.account
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
    customer_contest = create(:contest, account: @customer_account)
    ensemble = create(:large_ensemble, account: @demo_account)

    entry = ContestEntry.new(
      contest: customer_contest,
      large_ensemble: ensemble,
      user: @demo_admin
    )

    assert_not entry.valid?
    assert entry.errors[:contest].any?
  end

  test "allows belongs_to associations from the same account" do
    set_current_user(@demo_admin)

    contest = create(:contest, account: @demo_account)
    ensemble = create(:large_ensemble, account: @demo_account)

    entry = ContestEntry.new(
      contest: contest,
      large_ensemble: ensemble,
      user: @demo_admin
    )

    assert entry.valid?
    assert_empty entry.errors[:contest]
    assert_empty entry.errors[:large_ensemble]
    assert_empty entry.errors[:user]
  end
end
