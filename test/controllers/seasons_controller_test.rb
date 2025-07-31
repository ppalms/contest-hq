require "test_helper"

class SeasonsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:demo_admin_a)
    sign_in_as(@user)
    @season = seasons(:one)
  end

  test "should get index" do
    get seasons_url
    assert_response :success
    assert_select "h1", "Contest Seasons"
  end

  test "should get new" do
    get new_season_url
    assert_response :success
    assert_select "h1", "New Season"
  end

  test "should create season" do
    assert_difference("Season.count") do
      post seasons_url, params: { season: { name: "2025", archived: false } }
    end

    assert_redirected_to seasons_url
    assert_equal "Season was successfully created.", flash[:notice]
  end

  test "should not create season with duplicate name in same account" do
    assert_no_difference("Season.count") do
      post seasons_url, params: { season: { name: @season.name, archived: false } }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_season_url(@season)
    assert_response :success
    assert_select "h1", "Edit Season"
  end

  test "should update season" do
    patch season_url(@season), params: { season: { name: "Updated Name" } }
    assert_redirected_to seasons_url
    assert_equal "Season was successfully updated.", flash[:notice]
  end

  test "should destroy season without contests" do
    season_without_contests = Season.create!(name: "Empty Season", account: @season.account)
    
    assert_difference("Season.count", -1) do
      delete season_url(season_without_contests)
    end

    assert_redirected_to seasons_url
    assert_equal "Season was successfully deleted.", flash[:notice]
  end

  test "should not destroy season with contests" do
    # Create a contest for this season to test restriction
    Contest.create!(name: "Test Contest", season: @season, account: @season.account)
    
    assert_no_difference("Season.count") do
      delete season_url(@season)
    end

    assert_redirected_to seasons_url
    assert_match "Cannot delete season with contests", flash[:alert]
  end

  test "should require admin role" do
    # Sign in as non-admin user
    sign_out
    sign_in_as(users(:demo_director_a))

    get seasons_url
    assert_response :redirect
    assert_redirected_to root_url
  end

  private

  def sign_out
    delete session_url(Current.session) if Current.session
  end
end