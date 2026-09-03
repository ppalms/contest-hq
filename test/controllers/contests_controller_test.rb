require "test_helper"

class ContestsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user, :account_admin)
    sign_in_as(@user)
    @season = create(:season, account: @user.account)
    @contest = create(:contest, account: @user.account, season: @season)
  end

  test "should get index" do
    get contests_url
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select "h1", "Contests"
  end

  test "should filter contests by season" do
    next_season = create(:season, account: @user.account)
    create(:contest,
      name: "Future Contest",
      season: next_season,
      account: @user.account,
      contest_start: Date.current + 1.year,
      contest_end: Date.current + 1.year + 1.day)

    get contests_url, params: { season_id: @season.id }
    assert_response :success
    assert_select "select#season_id option[selected][value=?]", @season.id.to_s

    get contests_url, params: { season_id: next_season.id }
    assert_response :success
    assert_select "select#season_id option[selected][value=?]", next_season.id.to_s
  end

  test "should default to current season" do
    @season.update!(archived: false)

    get contests_url
    assert_response :redirect
    follow_redirect!
    assert_response :success
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
