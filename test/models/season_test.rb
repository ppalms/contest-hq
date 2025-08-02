require "test_helper"

class SeasonTest < ActiveSupport::TestCase
  def setup
    @user = users(:demo_admin_a)
    @account = @user.account

    set_current_user(@user)
  end

  test "validates presence of name" do
    season = Season.new(account: accounts(:demo))
    assert_not season.valid?
    assert_includes season.errors[:name], "can't be blank"
  end

  test "validates uniqueness of name within account" do
    account = accounts(:demo)
    Season.create!(name: "2026", account: account)

    duplicate_season = Season.new(name: "2026", account: account)
    assert_not duplicate_season.valid?
    assert_includes duplicate_season.errors[:name], "has already been taken"
  end

  test "allows same name across different accounts" do
    account_one = accounts(:demo)
    account_two = accounts(:customer)

    Season.create!(name: "2026", account: account_one)
    season_two = Season.new(name: "2026", account: account_two)

    assert season_two.valid?
  end

  test "current scope returns non-archived seasons ordered by creation" do
    account = accounts(:demo)
    Contest.where(account: account).destroy_all
    account.seasons.destroy_all

    Season.create!(name: "2026", account: account, archived: true)
    new_season = Season.create!(name: "2027", account: account, archived: false)

    assert_equal [ new_season ], Season.current.to_a
  end

  test "current_season returns most recent non-archived season" do
    account = accounts(:demo)
    Contest.where(account: account).destroy_all
    account.seasons.destroy_all

    Season.create!(name: "2026", account: account, archived: true)
    current_season = Season.create!(name: "2027", account: account, archived: false)

    assert_equal current_season, Season.current_season
  end

  test "display_name shows archived status" do
    season = Season.new(name: "2022", archived: false)
    assert_equal "2022", season.display_name

    season.archived = true
    assert_equal "2022 (Archived)", season.display_name
  end

  test "restricts deletion when contests exist" do
    season = seasons(:demo_2024)
    Contest.create!(name: "Test Contest", season: season, account: season.account)

    assert_raises ActiveRecord::RecordNotDestroyed do
      season.destroy!
    end
  end
end
