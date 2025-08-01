require "test_helper"

class SeasonTest < ActiveSupport::TestCase
  test "validates presence of name" do
    season = Season.new(account: accounts(:one))
    assert_not season.valid?
    assert_includes season.errors[:name], "can't be blank"
  end

  test "validates uniqueness of name within account" do
    account = accounts(:one)
    Season.create!(name: "2024", account: account)

    duplicate_season = Season.new(name: "2024", account: account)
    assert_not duplicate_season.valid?
    assert_includes duplicate_season.errors[:name], "has already been taken"
  end

  test "allows same name across different accounts" do
    account_one = accounts(:one)
    account_two = accounts(:two)

    Season.create!(name: "2024", account: account_one)
    season_two = Season.new(name: "2024", account: account_two)
    
    assert season_two.valid?
  end

  test "current scope returns non-archived seasons ordered by creation" do
    account = accounts(:one)
    old_season = Season.create!(name: "2023", account: account, archived: true)
    current_season = Season.create!(name: "2024", account: account, archived: false)
    
    assert_equal [current_season], Season.current.to_a
  end

  test "current_season returns most recent non-archived season" do
    account = accounts(:one)
    old_season = Season.create!(name: "2023", account: account, archived: true)
    current_season = Season.create!(name: "2024", account: account, archived: false)
    
    assert_equal current_season, Season.current_season
  end

  test "display_name shows archived status" do
    season = Season.new(name: "2024", archived: false)
    assert_equal "2024", season.display_name

    season.archived = true
    assert_equal "2024 (Archived)", season.display_name
  end

  test "restricts deletion when contests exist" do
    season = seasons(:one)
    contest = Contest.create!(name: "Test Contest", season: season, account: season.account)
    
    assert_raises ActiveRecord::DeleteRestrictionError do
      season.destroy!
    end
  end
end