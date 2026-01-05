require "application_system_test_case"

class PrescribedMusicTest < ApplicationSystemTestCase
  setup do
    @admin = users(:demo_admin_a)
    @director = users(:demo_director_a)
    @season = seasons(:demo_2025)
    @school_class = school_classes(:demo_school_class_a)
  end

  test "admin can create prescribed music" do
    sign_in_as(@admin)
    visit prescribed_music_index_url

    click_on "Add Prescribed Music"

    fill_in "Title", with: "Test Symphony"
    fill_in "Composer", with: "Test Composer"
    select @season.name, from: "Season"
    select @school_class.name, from: "School class"

    click_on "Create"

    assert_text "Prescribed music was successfully created"
    assert_text "Test Symphony"
    assert_text "Test Composer"
  end

  test "admin can edit prescribed music" do
    sign_in_as(@admin)
    prescribed_music = prescribed_musics(:demo_class_a_music_one)

    visit prescribed_music_index_url(season_id: @season.id)

    within "#prescribed_music_#{prescribed_music.id}" do
      click_on "Edit"
    end

    fill_in "Title", with: "Updated Symphony"
    click_on "Update"

    assert_text "Prescribed music was successfully updated"
    assert_text "Updated Symphony"
  end

  test "admin can delete prescribed music" do
    sign_in_as(@admin)
    prescribed_music = prescribed_musics(:demo_class_a_music_one)

    visit prescribed_music_index_url(season_id: @season.id)

    within "#prescribed_music_#{prescribed_music.id}" do
      accept_confirm do
        click_on "Delete"
      end
    end

    assert_text "Prescribed music was successfully deleted"
    assert_no_text prescribed_music.title
  end

  test "director can view but not create prescribed music" do
    sign_in_as(@director)
    visit prescribed_music_index_url

    assert_text "Prescribed Music"
    assert_no_text "Add Prescribed Music"
  end

  test "director can select prescribed music when creating contest entry" do
    sign_in_as(@director)
    contest = contests(:demo_contest_a)
    prescribed_music = prescribed_musics(:demo_class_a_music_one)

    visit contest_url(contest)
    click_on "Register"

    select users(:demo_director_a).conducted_ensembles.first.name, from: "Large ensemble"
    click_on "Continue"

    click_on "Select Prescribed Music"

    assert_text "Select Prescribed Music"
    assert_text prescribed_music.title
    assert_text prescribed_music.composer

    within "form[action*='#{prescribed_music.id}']" do
      click_on "button"
    end

    assert_text "Prescribed music was added to your contest entry"
    assert_text prescribed_music.title
    assert_text "Prescribed Music"
  end

  test "season filter works on prescribed music index" do
    sign_in_as(@admin)
    visit prescribed_music_index_url

    select @season.name, from: "Season"

    assert_text prescribed_musics(:demo_class_a_music_one).title
    assert_no_text prescribed_musics(:demo_archived_music).title
  end

  test "school class filter works on prescribed music index" do
    sign_in_as(@admin)
    visit prescribed_music_index_url(season_id: @season.id)

    select @school_class.name, from: "School Class"

    assert_text prescribed_musics(:demo_class_a_music_one).title
    assert_no_text prescribed_musics(:demo_class_b_music_one).title
  end
end
