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

  test "rejects prescribed music from wrong season" do
    # demo_class_a_music_one is from demo_2025 season, but contest is demo_2024
    prescribed = prescribed_musics(:demo_class_a_music_one)
    music = @contest_entry.music_selections.new(prescribed_music: prescribed)

    assert_not music.valid?
    assert_includes music.errors[:prescribed_music], "must be from the 2024 Season season"
  end

  test "rejects prescribed music from wrong school class" do
    # demo_2024_class_b_music_one would be wrong class (B instead of A)
    # First, let's create a class B prescribed music for 2024 season
    prescribed = PrescribedMusic.create!(
      title: "Test Class B Music",
      composer: "Test Composer",
      season: seasons(:demo_2024),
      school_class: school_classes(:demo_school_class_b),
      account: accounts(:demo)
    )
    
    music = @contest_entry.music_selections.new(prescribed_music: prescribed)

    assert_not music.valid?
    assert_includes music.errors[:prescribed_music], "must be for 2-A schools"
  end

  test "accepts prescribed music with correct season and school class" do
    # demo_2024_class_a_music_one has correct season (demo_2024) and class (A)
    prescribed = prescribed_musics(:demo_2024_class_a_music_one)
    music = @contest_entry.music_selections.new(prescribed_music: prescribed)

    assert music.valid?
  end

  test "allows custom music without prescribed_music validation" do
    music = @contest_entry.music_selections.new(
      title: "Custom Symphony",
      composer: "Custom Composer"
    )

    assert music.valid?
  end
end
