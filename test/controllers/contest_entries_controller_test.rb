require "test_helper"

class ContestEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_with_ensemble = create(:user, :director)
    set_current_user(@user_with_ensemble)
    @ensemble = create(:large_ensemble, account: @user_with_ensemble.account)
    @user_without_ensemble = create(:user, :director, account: @user_with_ensemble.account)
    @contest = create(:contest, account: @user_with_ensemble.account)
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
    account = @user_with_ensemble.account
    restricted_contest = create(:contest, account: account)
    class_2a = create(:school_class, name: "2-A", account: account)
    class_3a = create(:school_class, name: "3-A", account: account)
    restricted_contest.school_classes << [ class_2a, class_3a ]

    school_1a = create(:school, account: account, school_class: create(:school_class, name: "1-A", account: account))
    create(:large_ensemble, account: account, school: school_1a)

    sign_in_as(@user_with_ensemble)

    get new_contest_entry_path(contest_id: restricted_contest.id)

    assert_redirected_to contest_path(restricted_contest)
    assert_match(/None of your ensembles are eligible/, flash[:alert])
    assert_match(/restricted to 2-A, 3-A schools/, flash[:alert])
  end

  test "should show new contest entry form when user has eligible ensembles for restricted contest" do
    account = @user_with_ensemble.account
    restricted_contest = create(:contest, account: account)
    class_2a = create(:school_class, name: "2-A", account: account)
    class_3a = create(:school_class, name: "3-A", account: account)
    restricted_contest.school_classes << [ class_2a, class_3a ]

    user_with_eligible_ensemble = create(:user, :director, account: account)
    set_current_user(user_with_eligible_ensemble)
    school_2a = create(:school, account: account, school_class: class_2a)
    create(:large_ensemble, account: account, school: school_2a)

    sign_in_as(user_with_eligible_ensemble)

    get new_contest_entry_path(contest_id: restricted_contest.id)

    assert_response :success
    assert_select "h1", text: "New Contest Entry"
  end

  test "should show previous music prompt when previous entry exists with music" do
    sign_in_as(@user_with_ensemble)
    set_current_user(@user_with_ensemble)

    ensemble = @user_with_ensemble.conducted_ensembles.first
    season = create(:season, account: @user_with_ensemble.account)
    contest1 = create(:contest, account: @user_with_ensemble.account, season: season)
    contest2 = create(:contest, account: @user_with_ensemble.account, season: season)

    entry1 = create(:contest_entry, contest: contest1, user: @user_with_ensemble, large_ensemble: ensemble)
    prescribed = create(:prescribed_music,
      account: @user_with_ensemble.account,
      season: season,
      school_class: ensemble.school.school_class)
    entry1.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed, position: 1)
    entry1.music_selections.create!(title: "Symphony", composer: "Jones", position: 2)
    entry1.music_selections.create!(title: "Overture", composer: "Brown", position: 3)

    entry2 = create(:contest_entry, contest: contest2, user: @user_with_ensemble, large_ensemble: ensemble)

    get contest_entry_path(contest_id: contest2.id, id: entry2.id)

    assert_response :success
    assert_select "#previous_music_prompt"
  end

  test "copy_music should copy music selections from previous entry" do
    sign_in_as(@user_with_ensemble)
    set_current_user(@user_with_ensemble)

    ensemble = @user_with_ensemble.conducted_ensembles.first
    season = create(:season, account: @user_with_ensemble.account)
    contest1 = create(:contest, account: @user_with_ensemble.account, season: season)
    contest2 = create(:contest, account: @user_with_ensemble.account, season: season)

    entry1 = create(:contest_entry, contest: contest1, user: @user_with_ensemble, large_ensemble: ensemble)
    prescribed = create(:prescribed_music,
      account: @user_with_ensemble.account,
      season: season,
      school_class: ensemble.school.school_class)
    entry1.music_selections.create!(title: "March", composer: "Smith", prescribed_music: prescribed, position: 1)
    entry1.music_selections.create!(title: "Symphony", composer: "Jones", position: 2)
    entry1.music_selections.create!(title: "Overture", composer: "Brown", position: 3)

    entry2 = create(:contest_entry, contest: contest2, user: @user_with_ensemble, large_ensemble: ensemble)

    assert_equal 0, entry2.music_selections.count

    post contest_entry_copy_music_path(contest_id: contest2.id, entry_id: entry2.id)

    entry2.reload
    assert_equal 3, entry2.music_selections.count
    assert_equal 1, entry2.music_selections.where.not(prescribed_music_id: nil).count
    assert_equal 2, entry2.music_selections.where(prescribed_music_id: nil).count
  end

  test "should reject cross-account large_ensemble_id" do
    sign_in_as(@user_with_ensemble)
    customer_ensemble = create(:large_ensemble)

    assert_no_difference "ContestEntry.count" do
      post contest_entries_path(contest_id: @contest.id), params: {
        contest_entry: { large_ensemble_id: customer_ensemble.id }
      }
    end

    assert_response :unprocessable_content
  end
end
