require "test_helper"

class MusicSelectionTest < ActiveSupport::TestCase
  setup do
    set_current_user(users(:demo_director_a))
    @contest_entry = contest_entries(:contest_a_school_a_ensemble_b)
  end

  test "prescribed? returns true when prescribed_music_id is present" do
    music = @contest_entry.music_selections.new(
      title: "March",
      composer: "Smith",
      prescribed_music: prescribed_musics(:demo_class_a_music_one)
    )

    assert music.prescribed?
  end

  test "prescribed? returns false when prescribed_music_id is nil" do
    music = @contest_entry.music_selections.new(
      title: "Symphony",
      composer: "Jones"
    )

    assert_not music.prescribed?
  end

  test "custom? returns true when prescribed_music_id is nil" do
    music = @contest_entry.music_selections.new(
      title: "Symphony",
      composer: "Jones"
    )

    assert music.custom?
  end

  test "custom? returns false when prescribed_music_id is present" do
    music = @contest_entry.music_selections.new(
      title: "March",
      composer: "Smith",
      prescribed_music: prescribed_musics(:demo_class_a_music_one)
    )

    assert_not music.custom?
  end

  test "populates title and composer from prescribed music" do
    prescribed = prescribed_musics(:demo_class_a_music_one)
    music = @contest_entry.music_selections.create!(prescribed_music: prescribed)

    assert_equal prescribed.title, music.title
    assert_equal prescribed.composer, music.composer
  end
end
