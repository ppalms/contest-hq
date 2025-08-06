require "test_helper"

class ContestsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:demo_admin_a)
    sign_in_as(@user)
    @season = seasons(:demo_2025)
    @contest = contests(:demo_contest_c)
  end

  test "should get index" do
    get contests_url
    assert_response :success
    assert_select "h1", "Contests"
  end

  test "should filter contests by season" do
    next_season = Season.create!(name: "2026", account: @season.account)
    Contest.create!(
      name: "Future Contest",
      season: next_season,
      account: @season.account,
      contest_start: Date.current + 1.year
    )

    # Test filtering by first season
    get contests_url, params: { season_id: @season.id }
    assert_response :success
    assert_select "select#season_id option[selected][value=?]", @season.id.to_s

    # Test filtering by second season
    get contests_url, params: { season_id: next_season.id }
    assert_response :success
    assert_select "select#season_id option[selected][value=?]", next_season.id.to_s
  end

  test "should default to current season" do
    # Mark our season as current (non-archived)
    @season.update!(archived: false)

    get contests_url
    assert_response :success
    # Should show the current season
    assert_select "select#season_id option[selected][value=?]", @season.id.to_s
  end

  test "should create contest with season" do
    assert_difference("Contest.count") do
      post contests_url, params: {
        contest: {
          name: "New Contest",
          season_id: @season.id,
          contest_start: Date.current,
          contest_end: Date.current + 1.day
        }
      }
    end

    assert_redirected_to contest_url(Contest.last)
    assert_equal @season.id, Contest.last.season_id
  end

  test "should require season for new contest" do
    assert_no_difference("Contest.count") do
      post contests_url, params: {
        contest: {
          name: "New Contest",
          contest_start: Date.current,
          contest_end: Date.current + 1.day
        }
      }
    end

    assert_response :unprocessable_content
  end
end
