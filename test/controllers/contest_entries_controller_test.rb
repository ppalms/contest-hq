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

  test "should redirect when no ensembles are eligible for restricted contest" do
    # demo_contest_c is restricted to 2A and 3A schools
    restricted_contest = contests(:demo_contest_c)

    # demo_director_a conducts ensembles from demo_school_a (1A school)
    sign_in_as(@user_with_ensemble)

    get new_contest_entry_path(contest_id: restricted_contest.id)

    assert_redirected_to contest_path(restricted_contest)
    assert_match(/None of your ensembles are eligible/, flash[:alert])
    assert_match(/restricted to 2-A, 3-A schools/, flash[:alert])
  end

  test "should show new contest entry form when user has eligible ensembles for restricted contest" do
    # demo_contest_c is restricted to 2A and 3A schools
    restricted_contest = contests(:demo_contest_c)

    # demo_director_b conducts ensembles from demo_school_b (2A school)
    user_with_eligible_ensemble = users(:demo_director_b)
    sign_in_as(user_with_eligible_ensemble)

    get new_contest_entry_path(contest_id: restricted_contest.id)

    assert_response :success
    assert_select "h1", text: "New Contest Entry"
  end
end
