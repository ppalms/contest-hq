require "test_helper"

class ContestTest < ActiveSupport::TestCase
  test "should require a contest season" do
    contest = Contest.new(
      name: "Test Contest",
      account: accounts(:ossaa)
    )
    assert_not contest.valid?
    assert_includes contest.errors[:contest_season], "can't be blank"
  end

  test "should be valid with all required fields" do
    contest = Contest.new(
      name: "Test Contest",
      contest_season: contest_seasons(:ossaa_season_a),
      account: accounts(:ossaa)
    )
    assert contest.valid?
  end
end
