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
    # Use prescribed music with correct season (demo_2024) and school class (A)
    prescribed = prescribed_musics(:demo_2024_class_a_music_one)

    assert_difference("MusicSelection.count") do
      post add_prescribed_contest_entry_selections_path(contest_id: @contest.id, entry_id: @contest_entry.id, prescribed_music_id: prescribed.id)
    end

    music = MusicSelection.last
    assert_equal prescribed.id, music.prescribed_music_id
    assert_equal prescribed.title, music.title
    assert_equal prescribed.composer, music.composer
  end

  test "should reject prescribed music from wrong season" do
    # demo_class_a_music_one is from demo_2025 season, but contest is demo_2024
    prescribed = prescribed_musics(:demo_class_a_music_one)

    assert_no_difference("MusicSelection.count") do
      assert_raises(ActiveRecord::RecordInvalid) do
        post add_prescribed_contest_entry_selections_path(contest_id: @contest.id, entry_id: @contest_entry.id, prescribed_music_id: prescribed.id)
      end
    end
  end

  test "should reject prescribed music from wrong school class" do
    # Create a Class B prescribed music for 2024 season (contest requires Class A)
    set_current_user(@user)
    prescribed = PrescribedMusic.create!(
      title: "Test Class B Music",
      composer: "Test Composer",
      season: seasons(:demo_2024),
      school_class: school_classes(:demo_school_class_b),
      account: accounts(:demo)
    )

    assert_no_difference("MusicSelection.count") do
      assert_raises(ActiveRecord::RecordInvalid) do
        post add_prescribed_contest_entry_selections_path(contest_id: @contest.id, entry_id: @contest_entry.id, prescribed_music_id: prescribed.id)
      end
    end
  end

  test "should replace existing prescribed music selection" do
    set_current_user(@user)
    # Use prescribed music with correct season and school class
    prescribed1 = prescribed_musics(:demo_2024_class_a_music_one)
    prescribed2 = prescribed_musics(:demo_2024_class_a_music_two)

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
