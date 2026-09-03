require "test_helper"

class SeasonTest < ActiveSupport::TestCase
  def setup
    @user = create(:user, :account_admin)
    @account = @user.account

    set_current_user(@user)
  end

  test "validates presence of name" do
    season = Season.new(account: @account)
    assert_not season.valid?
    assert_includes season.errors[:name], "can't be blank"
  end

  test "validates uniqueness of name within account" do
    Season.create!(name: "2026", account: @account)

    duplicate_season = Season.new(name: "2026", account: @account)
    assert_not duplicate_season.valid?
    assert_includes duplicate_season.errors[:name], "has already been taken"
  end

  test "allows same name across different accounts" do
    account_one = @account
    account_two = create(:account)

    Season.create!(name: "2026", account: account_one, ordinal: 10)
    season_two = Season.new(name: "2026", account: account_two, ordinal: 10)

    assert season_two.valid?
  end

  test "current scope returns non-archived seasons ordered by ordinal" do
    Contest.where(account: @account).destroy_all
    PrescribedMusic.where(account: @account).destroy_all
    @account.seasons.destroy_all

    Season.create!(name: "2026", account: @account, archived: true, ordinal: 2)
    new_season = Season.create!(name: "2027", account: @account, archived: false, ordinal: 3)

    assert_equal [ new_season ], Season.current.to_a
  end

  test "current_season returns season with highest ordinal" do
    Contest.where(account: @account).destroy_all
    PrescribedMusic.where(account: @account).destroy_all
    @account.seasons.destroy_all

    Season.create!(name: "2026", account: @account, archived: true, ordinal: 2)
    current_season = Season.create!(name: "2027", account: @account, archived: false, ordinal: 3)

    assert_equal current_season, Season.current_season
  end

  test "assigns ordinal automatically on create" do
    existing = create(:season, account: @account)

    new_season = Season.create!(name: "2028", account: @account)

    assert new_season.ordinal > existing.ordinal
  end

  test "validates uniqueness of ordinal within account" do
    existing_season = create(:season, account: @account)

    duplicate_ordinal_season = Season.new(
      name: "Different Name",
      account: @account,
      ordinal: existing_season.ordinal
    )

    assert_not duplicate_ordinal_season.valid?
    assert_includes duplicate_ordinal_season.errors[:ordinal], "has already been taken"
  end

  test "allows same ordinal across different accounts" do
    demo_season = create(:season, account: @account)
    customer_account = create(:account)

    same_ordinal_season = Season.new(
      name: "2025",
      account: customer_account,
      ordinal: demo_season.ordinal
    )

    assert same_ordinal_season.valid?
  end

  test "display_name shows archived status" do
    season = Season.new(name: "2022", archived: false)
    assert_equal "2022", season.display_name

    season.archived = true
    assert_equal "2022 (Archived)", season.display_name
  end

  test "restricts deletion when contests exist" do
    season = create(:season, account: @account)
    Contest.create!(name: "Test Contest", season: season, account: season.account)

    assert_raises ActiveRecord::RecordNotDestroyed do
      season.destroy!
    end
  end
end
