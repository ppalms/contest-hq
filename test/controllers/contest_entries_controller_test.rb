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

  test "should show previous music prompt when previous entry exists with music" do
    sign_in_as(@user_with_ensemble)
    set_current_user(@user_with_ensemble)

    ensemble = @user_with_ensemble.conducted_ensembles.first
    contest1 = @contest
    contest2 = contests(:demo_contest_b)

    entry1 = ContestEntry.create!(contest: contest1, user: @user_with_ensemble, large_ensemble: ensemble)
    entry1.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed_musics(:demo_2024_class_a_music_one), position: 1)
    entry1.music_selections.create!(title: "Symphony", composer: "Jones", position: 2)
    entry1.music_selections.create!(title: "Overture", composer: "Brown", position: 3)

    entry2 = ContestEntry.create!(contest: contest2, user: @user_with_ensemble, large_ensemble: ensemble)

    get contest_entry_path(contest_id: contest2.id, id: entry2.id)

    assert_response :success
    assert_select "#previous_music_prompt"
  end

  test "copy_music should copy music selections from previous entry" do
    sign_in_as(@user_with_ensemble)
    set_current_user(@user_with_ensemble)

    ensemble = @user_with_ensemble.conducted_ensembles.first
    contest1 = @contest
    contest2 = contests(:demo_contest_b)

    entry1 = ContestEntry.create!(contest: contest1, user: @user_with_ensemble, large_ensemble: ensemble)
    entry1.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed_musics(:demo_2024_class_a_music_one), position: 1)
    entry1.music_selections.create!(title: "Symphony", composer: "Jones", position: 2)
    entry1.music_selections.create!(title: "Overture", composer: "Brown", position: 3)

    entry2 = ContestEntry.create!(contest: contest2, user: @user_with_ensemble, large_ensemble: ensemble)

    assert_equal 0, entry2.music_selections.count

    post contest_entry_copy_music_path(contest_id: contest2.id, entry_id: entry2.id)

    entry2.reload
    assert_equal 3, entry2.music_selections.count
    assert_equal 1, entry2.music_selections.where.not(prescribed_music_id: nil).count
    assert_equal 2, entry2.music_selections.where(prescribed_music_id: nil).count
  end
end
