require "test_helper"

class PrescribedMusicTest < ActiveSupport::TestCase
  def setup
    set_current_user(create(:user, :account_admin))
  end

  test "should be valid with all required attributes" do
    prescribed_music = build(:prescribed_music)
    assert prescribed_music.valid?
  end

  test "should require title" do
    prescribed_music = build(:prescribed_music, title: nil)
    assert_not prescribed_music.valid?
    assert_includes prescribed_music.errors[:title], "can't be blank"
  end

  test "should require composer" do
    prescribed_music = build(:prescribed_music, composer: nil)
    assert_not prescribed_music.valid?
    assert_includes prescribed_music.errors[:composer], "can't be blank"
  end

  test "should require season" do
    prescribed_music = build(:prescribed_music, season: nil)
    assert_not prescribed_music.valid?
    assert_includes prescribed_music.errors[:season], "can't be blank"
  end

  test "should require school_class" do
    prescribed_music = build(:prescribed_music, school_class: nil)
    assert_not prescribed_music.valid?
    assert_includes prescribed_music.errors[:school_class], "can't be blank"
  end

  test "should belong to season" do
    prescribed_music = create(:prescribed_music)
    assert_equal prescribed_music.season, prescribed_music.season
  end

  test "should belong to school_class" do
    prescribed_music = create(:prescribed_music)
    assert_equal prescribed_music.school_class, prescribed_music.school_class
  end

  test "should have many music_selections" do
    prescribed_music = create(:prescribed_music)
    assert_respond_to prescribed_music, :music_selections
  end

  test "for_season scope should filter by season" do
    season = create(:season)
    school_class = create(:school_class, account: season.account)
    music = create(:prescribed_music, season: season, school_class: school_class, account: season.account)
    other = create(:prescribed_music, account: season.account)

    results = PrescribedMusic.for_season(season.id)
    assert_includes results, music
    assert_not_includes results, other
  end

  test "for_school_class scope should filter by school class" do
    season = create(:season)
    school_class = create(:school_class, account: season.account)
    other_class = create(:school_class, account: season.account)
    music = create(:prescribed_music, season: season, school_class: school_class, account: season.account)
    other = create(:prescribed_music, season: season, school_class: other_class, account: season.account)

    results = PrescribedMusic.for_school_class(school_class.id)
    assert_includes results, music
    assert_not_includes results, other
  end

  test "by_title scope should order by title" do
    season = create(:season)
    school_class = create(:school_class, account: season.account)
    create(:prescribed_music, title: "Zebra", season: season, school_class: school_class, account: season.account)
    create(:prescribed_music, title: "Apple", season: season, school_class: school_class, account: season.account)

    results = PrescribedMusic.for_season(season.id)
                             .for_school_class(school_class.id)
                             .by_title
    titles = results.pluck(:title)
    assert_equal titles.sort, titles
  end

  test "display_name should return title and composer" do
    prescribed_music = create(:prescribed_music, title: "Symphony No. 5", composer: "Ludwig van Beethoven")
    assert_equal "Symphony No. 5 - Ludwig van Beethoven", prescribed_music.display_name
  end

  test "should be account scoped" do
    demo_music = create(:prescribed_music)
    other_account = create(:account)
    set_current_user(create(:user, :account_admin, account: other_account))
    results = PrescribedMusic.where(id: demo_music.id)
    assert_empty results
  end

  test "destroying prescribed music should destroy associated music selections" do
    contest_entry = create(:contest_entry)
    prescribed_music = create(
      :prescribed_music,
      account: contest_entry.account,
      season: contest_entry.contest.season,
      school_class: contest_entry.large_ensemble.school.school_class
    )

    MusicSelection.create!(
      contest_entry: contest_entry,
      prescribed_music: prescribed_music,
      title: prescribed_music.title,
      composer: prescribed_music.composer
    )

    assert_difference "MusicSelection.count", -1 do
      prescribed_music.destroy
    end
  end
end
