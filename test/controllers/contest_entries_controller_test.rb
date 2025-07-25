require "test_helper"

class ContestEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @contest = contests(:demo_contest_a)
    @user_with_ensemble = users(:demo_director_a)
    @user_without_ensemble = users(:demo_director_c)
  end

  test "should redirect to new large ensemble when user has no ensembles" do
    sign_in_as @user_without_ensemble

    get new_contest_entry_path(contest_id: @contest.id)

    assert_redirected_to new_roster_large_ensemble_path(redirect_to_contest_entry: @contest.id)
    assert_equal "You need to create a large ensemble before registering for a contest.", flash[:notice]
  end

  test "should show new contest entry form when user has ensembles" do
    sign_in_as(@user_with_ensemble)

    get new_contest_entry_path(contest_id: @contest.id)

    assert_response :success
    assert_select "h1", text: "New Contest Entry"
  end

  test "should pre-select ensemble when returning from ensemble creation" do
    sign_in_as(@user_with_ensemble)

    ensemble = @user_with_ensemble.conducted_ensembles.first
    get new_contest_entry_path(contest_id: @contest.id, large_ensemble_id: ensemble.id)

    assert_response :success
    assert_select "select#large_ensemble_id option[selected][value=?]", ensemble.id.to_s
  end
end
