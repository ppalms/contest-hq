require "application_system_test_case"

class PrescribedMusicTest < ApplicationSystemTestCase
  setup do
    @admin = users(:demo_admin_a)
    @director = users(:demo_director_a)
    @season = seasons(:demo_2025)
    @school_class = school_classes(:demo_school_class_a)
  end

  test "admin can create prescribed music" do
    log_in_as(@admin)
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
    log_in_as(@admin)
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
    log_in_as(@admin)
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
    log_in_as(@director)
    visit prescribed_music_index_url

    assert_text "Prescribed Music"
    assert_no_text "Add Prescribed Music"
  end

  test "director can select prescribed music when creating contest entry" do
    # Use demo_director_b who conducts demo_school_b_ensemble_a (school_class_b)
    # This ensemble is eligible for demo_contest_c which is in demo_2025 season
    director = users(:demo_director_b)
    log_in_as(director)

    contest = contests(:demo_contest_c)
    prescribed_music = prescribed_musics(:demo_class_b_music_one)
    ensemble = large_ensembles(:demo_school_b_ensemble_a)

    visit contest_url(contest)

    # Verify we can see the Register button
    assert_text "Register"
    click_on "Register"

    # Wait for the form to load and verify we're on the registration page
    assert_text "Preferred Performance Time"

    # Select the ensemble if the select box is present
    # (it might be auto-selected if there's only one eligible ensemble)
    if page.has_select?("Large ensemble")
      select ensemble.name, from: "Large ensemble"
    end

    click_on "Continue"

    # Verify we're on the contest entry page
    assert_text ensemble.name

    click_on "Add Prescribed Music"

    # Search for prescribed music
    fill_in "search", with: "Rhapsody"
    click_on "Search"

    # Verify search results appear
    assert_text prescribed_music.title
    assert_text prescribed_music.composer

    # Click the Select button in the row with the prescribed music
    row = find("tr", text: prescribed_music.title)
    within row do
      click_on "Select"
    end

    # Verify we're back on the contest entry page with the music added
    assert_text "Music selection added successfully"
    assert_text "Prescribed"
    assert_text prescribed_music.title
  end

  test "season filter works on prescribed music index" do
    log_in_as(@admin)
    visit prescribed_music_index_url

    select @season.name, from: "Season"

    assert_text prescribed_musics(:demo_class_a_music_one).title
    assert_no_text prescribed_musics(:demo_archived_music).title
  end

  test "school class filter works on prescribed music index" do
    log_in_as(@admin)
    visit prescribed_music_index_url(season_id: @season.id)

    select @school_class.name, from: "School Class"

    assert_text prescribed_musics(:demo_class_a_music_one).title
    assert_no_text prescribed_musics(:demo_class_b_music_one).title
  end

  test "prescribed music search is case-insensitive" do
    director = users(:demo_director_b)
    log_in_as(director)

    contest = contests(:demo_contest_c)
    ensemble = large_ensembles(:demo_school_b_ensemble_a)

    visit contest_url(contest)
    click_on "Register"

    if page.has_select?("Large ensemble")
      select ensemble.name, from: "Large ensemble"
    end

    click_on "Continue"
    click_on "Add Prescribed Music"

    # Search with lowercase "rhapsody" should find "Rhapsody in Blue"
    fill_in "search", with: "rhapsody"
    click_on "Search"

    assert_text "Rhapsody in Blue"
    assert_text "George Gershwin"
  end

  test "empty search returns all prescribed music for school class" do
    director = users(:demo_director_b)
    log_in_as(director)

    contest = contests(:demo_contest_c)
    ensemble = large_ensembles(:demo_school_b_ensemble_a)

    visit contest_url(contest)
    click_on "Register"

    if page.has_select?("Large ensemble")
      select ensemble.name, from: "Large ensemble"
    end

    click_on "Continue"
    click_on "Add Prescribed Music"

    # Empty search should return all prescribed music for school_class_b
    fill_in "search", with: ""
    click_on "Search"

    # Should see all 5 prescribed music pieces for demo_school_class_b
    assert_text "Rhapsody in Blue"
    assert_text "American in Paris"
    assert_text "Appalachian Spring"
    assert_text "West Side Story Suite"
    assert_text "Candide Overture"
  end
end
