require "test_helper"

class MusicSelectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :director)
    set_current_user(@user)
    @contest_entry = create(:contest_entry, user: @user)
    @contest = @contest_entry.contest
    sign_in_as(@user)

    @contest_entry.music_selections.destroy_all
    create(:prescribed_music,
      account: @contest_entry.account,
      season: @contest_entry.contest.season,
      school_class: @contest_entry.large_ensemble.school.school_class)
  end

  test "index shows all music selections for entry" do
    get contest_entry_music_selections_path(contest_id: @contest.id, entry_id: @contest_entry.id)
    assert_response :success
    assert_select "h1", "Music Selections"
  end

  test "new renders form for custom music" do
    get new_contest_entry_music_selection_path(contest_id: @contest.id, entry_id: @contest_entry.id, type: "custom")
    assert_response :success
    assert_select "h1", "Add Custom Music"
    assert_select "input[name='music_selection[title]']"
    assert_select "input[name='music_selection[composer]']"
  end

  test "create adds custom music selection" do
    assert_difference "@contest_entry.music_selections.count", 1 do
      post contest_entry_music_selections_path(contest_id: @contest.id, entry_id: @contest_entry.id), params: {
        music_selection: {
          title: "New Symphony",
          composer: "New Composer",
          position: 1
        }
      }
    end

    assert_redirected_to contest_entry_path(@contest, @contest_entry)
  end

  test "create adds prescribed music selection" do
    prescribed = create(:prescribed_music,
      account: @contest_entry.account,
      season: @contest_entry.contest.season,
      school_class: @contest_entry.large_ensemble.school.school_class)

    assert_difference "@contest_entry.music_selections.count", 1 do
      post contest_entry_music_selections_path(contest_id: @contest.id, entry_id: @contest_entry.id), params: {
        music_selection: {
          prescribed_music_id: prescribed.id,
          position: 1
        }
      }
    end

    assert_redirected_to contest_entry_path(@contest, @contest_entry)
  end

  test "edit renders form for existing custom selection" do
    selection = @contest_entry.music_selections.create!(title: "Test", composer: "Composer", position: 1, account: @contest.account)

    get edit_contest_entry_music_selection_path(contest_id: @contest.id, entry_id: @contest_entry.id, id: selection.id)
    assert_response :success
    assert_select "h1", "Edit Music Selection"
  end

  test "update modifies existing custom selection" do
    selection = @contest_entry.music_selections.create!(title: "Old Title", composer: "Old Composer", position: 1, account: @contest.account)

    patch contest_entry_music_selection_path(contest_id: @contest.id, entry_id: @contest_entry.id, id: selection.id), params: {
      music_selection: {
        title: "New Title",
        composer: "New Composer"
      }
    }

    assert_redirected_to contest_entry_path(@contest, @contest_entry)
    selection.reload
    assert_equal "New Title", selection.title
    assert_equal "New Composer", selection.composer
  end

  test "destroy removes selection" do
    selection = @contest_entry.music_selections.create!(title: "Test", composer: "Composer", position: 1, account: @contest.account)

    assert_difference "@contest_entry.music_selections.count", -1 do
      delete contest_entry_music_selection_path(contest_id: @contest.id, entry_id: @contest_entry.id, id: selection.id)
    end

    assert_redirected_to contest_entry_path(@contest, @contest_entry)
  end

  test "new_prescribed renders search page" do
    get new_prescribed_contest_entry_music_selections_path(contest_id: @contest.id, entry_id: @contest_entry.id)
    assert_response :success
    assert_select "h1", "Select Prescribed Music"
    assert_select "input[name='search']"
  end

  test "new_prescribed searches and filters prescribed music" do
    get new_prescribed_contest_entry_music_selections_path(contest_id: @contest.id, entry_id: @contest_entry.id, search: "")
    assert_response :success

    assert_select "table"
  end
end
