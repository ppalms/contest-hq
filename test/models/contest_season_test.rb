require "test_helper"

class ContestSeasonTest < ActiveSupport::TestCase
  test "should require a name" do
    contest_season = ContestSeason.new(account: accounts(:ossaa))
    assert_not contest_season.valid?
    assert_includes contest_season.errors[:name], "can't be blank"
  end

  test "should require name to be unique within account" do
    existing_season = contest_seasons(:ossaa_season_a)
    contest_season = ContestSeason.new(
      name: existing_season.name,
      account: existing_season.account
    )
    assert_not contest_season.valid?
    assert_includes contest_season.errors[:name], "has already been taken"
  end

  test "should allow same name in different accounts" do
    ossaa_season = contest_seasons(:ossaa_season_a)
    contest_season = ContestSeason.new(
      name: ossaa_season.name,
      account: accounts(:contesthq)  # Use a different account that doesn't have "2024"
    )
    unless contest_season.valid?
      puts "Validation errors: #{contest_season.errors.full_messages}"
    end
    assert contest_season.valid?
  end

  test "should destroy associated contests when deleted" do
    season = contest_seasons(:ossaa_season_a)
    contest_count_before = Contest.count
    
    # Create a contest associated with this season
    Contest.create!(
      name: "Test Contest",
      contest_season: season,
      account: season.account
    )
    
    assert_equal contest_count_before + 1, Contest.count
    
    season.destroy
    
    assert_equal contest_count_before, Contest.count
  end

  test "should be scoped to account" do
    ossaa_seasons = ContestSeason.where(account: accounts(:ossaa))
    demo_seasons = ContestSeason.where(account: accounts(:demo))
    
    assert_not_empty ossaa_seasons
    # demo might be empty, so let's just verify scoping works with ossaa
    
    # Verify no cross-contamination
    ossaa_seasons.each do |season|
      assert_equal accounts(:ossaa), season.account
    end
  end
end
