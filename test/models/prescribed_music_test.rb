require "test_helper"

class PrescribedMusicTest < ActiveSupport::TestCase
  def setup
    set_current_user(users(:demo_admin_a))
  end

  test "should be valid with all required attributes" do
    prescribed_music = PrescribedMusic.new(
      title: "Test Symphony",
      composer: "Test Composer",
      season: seasons(:demo_2025),
      school_class: school_classes(:demo_school_class_a)
    )
    assert prescribed_music.valid?
  end

  test "should require title" do
    prescribed_music = PrescribedMusic.new(
      composer: "Test Composer",
      season: seasons(:demo_2025),
      school_class: school_classes(:demo_school_class_a)
    )
    assert_not prescribed_music.valid?
    assert_includes prescribed_music.errors[:title], "can't be blank"
  end

  test "should require composer" do
    prescribed_music = PrescribedMusic.new(
      title: "Test Symphony",
      season: seasons(:demo_2025),
      school_class: school_classes(:demo_school_class_a)
    )
    assert_not prescribed_music.valid?
    assert_includes prescribed_music.errors[:composer], "can't be blank"
  end

  test "should require season" do
    prescribed_music = PrescribedMusic.new(
      title: "Test Symphony",
      composer: "Test Composer",
      school_class: school_classes(:demo_school_class_a)
    )
    assert_not prescribed_music.valid?
    assert_includes prescribed_music.errors[:season], "can't be blank"
  end

  test "should require school_class" do
    prescribed_music = PrescribedMusic.new(
      title: "Test Symphony",
      composer: "Test Composer",
      season: seasons(:demo_2025)
    )
    assert_not prescribed_music.valid?
    assert_includes prescribed_music.errors[:school_class], "can't be blank"
  end

  test "should belong to season" do
    prescribed_music = prescribed_musics(:demo_class_a_music_one)
    assert_equal seasons(:demo_2025), prescribed_music.season
  end

  test "should belong to school_class" do
    prescribed_music = prescribed_musics(:demo_class_a_music_one)
    assert_equal school_classes(:demo_school_class_a), prescribed_music.school_class
  end

  test "should have many music_selections" do
    prescribed_music = prescribed_musics(:demo_class_a_music_one)
    assert_respond_to prescribed_music, :music_selections
  end

  test "for_season scope should filter by season" do
    results = PrescribedMusic.for_season(seasons(:demo_2025).id)
    assert_includes results, prescribed_musics(:demo_class_a_music_one)
    assert_not_includes results, prescribed_musics(:demo_archived_music)
  end

  test "for_school_class scope should filter by school class" do
    results = PrescribedMusic.for_school_class(school_classes(:demo_school_class_a).id)
    assert_includes results, prescribed_musics(:demo_class_a_music_one)
    assert_not_includes results, prescribed_musics(:demo_class_b_music_one)
  end

  test "by_title scope should order by title" do
    results = PrescribedMusic.for_season(seasons(:demo_2025).id)
                             .for_school_class(school_classes(:demo_school_class_a).id)
                             .by_title
    titles = results.pluck(:title)
    assert_equal titles.sort, titles
  end

  test "display_name should return title and composer" do
    prescribed_music = prescribed_musics(:demo_class_a_music_one)
    assert_equal "Symphony No. 5 - Ludwig van Beethoven", prescribed_music.display_name
  end

  test "should be account scoped" do
    set_current_user(users(:customer_admin_a))
    demo_music = PrescribedMusic.where(id: prescribed_musics(:demo_class_a_music_one).id)
    assert_empty demo_music
  end

  test "destroying prescribed music should destroy associated music selections" do
    prescribed_music = prescribed_musics(:demo_class_a_music_one)

    music_selection = MusicSelection.create!(
      contest_entry: contest_entries(:contest_a_school_a_ensemble_a),
      prescribed_music: prescribed_music,
      title: prescribed_music.title,
      composer: prescribed_music.composer
    )

    assert_difference "MusicSelection.count", -1 do
      prescribed_music.destroy
    end
  end
end
