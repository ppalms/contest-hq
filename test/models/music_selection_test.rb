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
    prescribed = prescribed_musics(:demo_2024_class_a_music_one)
    music = @contest_entry.music_selections.create!(prescribed_music: prescribed)

    assert_equal prescribed.title, music.title
    assert_equal prescribed.composer, music.composer
  end

  test "rejects prescribed music from wrong season" do
    # demo_class_a_music_one is from demo_2025 season, but contest is demo_2024
    prescribed = prescribed_musics(:demo_class_a_music_one)
    music = @contest_entry.music_selections.new(prescribed_music: prescribed)

    assert_not music.valid?
    assert_includes music.errors[:prescribed_music], "must be from the 2024 season"
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
    assert_includes music.errors[:prescribed_music], "must be for 1-A schools"
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

  test "position must be explicitly set on create" do
    @contest_entry.music_selections.destroy_all

    selection1 = @contest_entry.music_selections.create!(title: "First", composer: "Composer 1", position: 1)
    assert_equal 1, selection1.position

    selection2 = @contest_entry.music_selections.create!(title: "Second", composer: "Composer 2", position: 2)
    assert_equal 2, selection2.position

    selection3 = @contest_entry.music_selections.create!(title: "Third", composer: "Composer 3", position: 3)
    assert_equal 3, selection3.position
  end

  test "position can be explicitly set on create" do
    @contest_entry.music_selections.destroy_all
    selection = @contest_entry.music_selections.create!(title: "Test", composer: "Composer", position: 2)
    assert_equal 2, selection.position
  end

  test "default scope returns selections in position order" do
    @contest_entry.music_selections.destroy_all
    selection1 = @contest_entry.music_selections.create!(title: "First", composer: "C1", position: 1)
    selection2 = @contest_entry.music_selections.create!(title: "Second", composer: "C2", position: 2)
    selection3 = @contest_entry.music_selections.create!(title: "Third", composer: "C3", position: 3)

    selections = @contest_entry.music_selections.to_a
    assert_equal [ selection1.id, selection2.id, selection3.id ], selections.map(&:id), "Selections should be ordered by position"
  end

  test "position updates maintain order" do
    @contest_entry.music_selections.destroy_all
    selection1 = @contest_entry.music_selections.create!(title: "First", composer: "C1", position: 1)
    selection2 = @contest_entry.music_selections.create!(title: "Second", composer: "C2", position: 2)
    selection3 = @contest_entry.music_selections.create!(title: "Third", composer: "C3", position: 3)

    selection1.position = 3
    selection1.save(validate: false)
    selection3.update!(position: 1)
    selection1.position = 3
    selection1.save!

    selections = @contest_entry.music_selections.reload.to_a
    assert_equal [ selection3.id, selection2.id, selection1.id ], selections.map(&:id)
  end

  test "prescribed music updates title and composer when changed" do
    @contest_entry.music_selections.destroy_all
    old_prescribed = prescribed_musics(:demo_2024_class_a_music_one)
    new_prescribed = prescribed_musics(:demo_2024_class_a_music_two)

    selection = @contest_entry.music_selections.create!(prescribed_music_id: old_prescribed.id, position: 1)
    assert_equal old_prescribed.title, selection.title

    selection.update!(prescribed_music_id: new_prescribed.id)
    assert_equal new_prescribed.title, selection.title
    assert_equal new_prescribed.composer, selection.composer
  end

  test "position can be reused after deletion" do
    @contest_entry.music_selections.destroy_all

    selection1 = @contest_entry.music_selections.create!(title: "First", composer: "C1", position: 1)
    selection2 = @contest_entry.music_selections.create!(title: "Second", composer: "C2", position: 2)

    selection1.destroy

    # Can now create a new selection at position 1
    selection3 = @contest_entry.music_selections.create!(title: "Third", composer: "C3", position: 1)
    assert_equal 1, selection3.position
  end

  test "validates position uniqueness within contest_entry" do
    @contest_entry.music_selections.destroy_all
    selection1 = @contest_entry.music_selections.create!(title: "First", composer: "C1", position: 1)
    selection2 = @contest_entry.music_selections.build(title: "Second", composer: "C2", position: 1)

    assert_not selection2.valid?
    assert_includes selection2.errors[:position], "has already been taken"
  end

  test "allows same position across different contest entries" do
    @contest_entry.music_selections.destroy_all
    other_entry = contest_entries(:contest_a_school_a_ensemble_a)
    other_entry.music_selections.destroy_all

    selection1 = @contest_entry.music_selections.create!(title: "First", composer: "C1", position: 1)
    selection2 = other_entry.music_selections.create!(title: "Second", composer: "C2", position: 1)

    assert selection1.valid?
    assert selection2.valid?
  end

  test "validates position is within allowed range based on contest requirements" do
    @contest_entry.music_selections.destroy_all
    contest = @contest_entry.contest
    contest.update!(required_prescribed_count: 1, required_custom_count: 2)

    selection = @contest_entry.music_selections.build(title: "Test", composer: "Composer", position: 4)

    assert_not selection.valid?
    assert_includes selection.errors[:position], "must be between 1 and 3"
  end

  test "allows position within valid range" do
    @contest_entry.music_selections.destroy_all
    contest = @contest_entry.contest
    contest.update!(required_prescribed_count: 1, required_custom_count: 2)

    selection1 = @contest_entry.music_selections.create!(title: "First", composer: "C1", position: 1)
    selection2 = @contest_entry.music_selections.create!(title: "Second", composer: "C2", position: 2)
    selection3 = @contest_entry.music_selections.create!(title: "Third", composer: "C3", position: 3)

    assert selection1.valid?
    assert selection2.valid?
    assert selection3.valid?
  end
end
