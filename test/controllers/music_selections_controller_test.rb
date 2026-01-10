require "test_helper"

class MusicSelectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:demo_director_a)
    @contest_entry = contest_entries(:contest_a_school_a_ensemble_b)
    @contest = @contest_entry.contest
    sign_in_as(@user)
  end

  test "should create custom music selection" do
    assert_difference("MusicSelection.count") do
      post contest_entry_selections_path(contest_id: @contest.id, entry_id: @contest_entry.id), params: {
        music_selection: {
          contest_entry_id: @contest_entry.id,
          title: "New Symphony",
          composer: "Test Composer"
        }
      }
    end

    assert_redirected_to contest_entry_path(@contest, @contest_entry)
  end

  test "should add prescribed music selection" do
    prescribed = prescribed_musics(:demo_class_a_music_one)

    assert_difference("MusicSelection.count") do
      post add_prescribed_contest_entry_selections_path(contest_id: @contest.id, entry_id: @contest_entry.id, prescribed_music_id: prescribed.id)
    end

    music = MusicSelection.last
    assert_equal prescribed.id, music.prescribed_music_id
    assert_equal prescribed.title, music.title
    assert_equal prescribed.composer, music.composer
  end

  test "should replace existing prescribed music selection" do
    set_current_user(@user)
    prescribed1 = prescribed_musics(:demo_class_a_music_one)
    prescribed2 = prescribed_musics(:demo_class_a_music_two)

    @contest_entry.music_selections.destroy_all
    @contest_entry.music_selections.create!(prescribed_music: prescribed1)

    assert_no_difference("MusicSelection.count") do
      post add_prescribed_contest_entry_selections_path(contest_id: @contest.id, entry_id: @contest_entry.id, prescribed_music_id: prescribed2.id)
    end

    @contest_entry.reload
    assert_equal 1, @contest_entry.music_selections.count
    assert_equal prescribed2.id, @contest_entry.prescribed_selection.prescribed_music_id
  end

  test "should destroy music selection" do
    set_current_user(@user)
    music = @contest_entry.music_selections.create!(title: "Test", composer: "Composer")

    assert_difference("MusicSelection.count", -1) do
      delete contest_entry_selection_path(contest_id: @contest.id, entry_id: @contest_entry.id, id: music.id)
    end

    assert_redirected_to contest_entry_path(@contest, @contest_entry)
  end
end
