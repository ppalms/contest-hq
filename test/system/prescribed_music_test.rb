require "application_system_test_case"

class PrescribedMusicTest < ApplicationSystemTestCase
  setup do
    @admin = create(:user, :account_admin)
    set_current_user(@admin)
    @director = create(:user, :director, account: @admin.account)
    @season = create(:season, account: @admin.account, name: "2025", ordinal: 3)
    @season_2024 = create(:season, account: @admin.account, name: "2024", ordinal: 2)
    @season_2023 = create(:season, account: @admin.account, name: "2023", ordinal: 1, archived: true)
    @school_class = create(:school_class, account: @admin.account, name: "1-A", ordinal: 1)
    @school_class_b = create(:school_class, account: @admin.account, name: "2-A", ordinal: 2)
    @music_one = create(:prescribed_music, account: @admin.account, season: @season, school_class: @school_class, title: "Symphony No. 5", composer: "Ludwig van Beethoven")
    @music_b_one = create(:prescribed_music, account: @admin.account, season: @season, school_class: @school_class_b, title: "Rhapsody in Blue", composer: "George Gershwin")
    @music_b_two = create(:prescribed_music, account: @admin.account, season: @season, school_class: @school_class_b, title: "American in Paris", composer: "George Gershwin")
    @music_b_three = create(:prescribed_music, account: @admin.account, season: @season, school_class: @school_class_b, title: "Appalachian Spring", composer: "Aaron Copland")
    @music_b_four = create(:prescribed_music, account: @admin.account, season: @season, school_class: @school_class_b, title: "West Side Story Suite", composer: "Leonard Bernstein")
    @music_b_five = create(:prescribed_music, account: @admin.account, season: @season, school_class: @school_class_b, title: "Candide Overture", composer: "Leonard Bernstein")
    @archived_music = create(:prescribed_music, account: @admin.account, season: @season_2023, school_class: @school_class, title: "Old Music", composer: "Old Composer")
    @director_b = create(:user, :director, account: @admin.account)
    @contest_c = create(:contest, account: @admin.account, season: @season)
    @contest_c.school_classes << @school_class_b
    @school_b = create(:school, account: @admin.account, school_class: @school_class_b)
    set_current_user(@director_b)
    @ensemble_b = create(:large_ensemble, account: @admin.account, school: @school_b)
  end

  test "admin can create prescribed music" do
    log_in_as(@admin)
    visit prescribed_music_index_url

    click_on "Add Prescribed Music"

    assert_selector "form.wide-form"

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
    prescribed_music = @music_one

    visit prescribed_music_index_url(season_id: @season.id)

    within "#prescribed_music_#{prescribed_music.id}" do
      click_on "Edit"
    end

    assert_selector "form.wide-form"

    fill_in "Title", with: "Updated Symphony"
    click_on "Update"

    assert_text "Prescribed music was successfully updated"
    assert_text "Updated Symphony"
  end

  test "admin can delete prescribed music" do
    log_in_as(@admin)
    prescribed_music = @music_one

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
    log_in_as(@director_b)

    visit contest_url(@contest_c)

    assert_text "Register"
    click_on "Register"

    assert_text "Preferred Performance Time"

    if page.has_select?("Large ensemble")
      select @ensemble_b.name, from: "Large ensemble"
    end

    click_on "Continue"

    assert_text @ensemble_b.name

    click_on "Add Prescribed Music"

    assert_selector "form#prescribed_search_form"
    fill_in "search", with: "Rhapsody"
    click_on "Search"

    assert_text @music_b_one.title
    assert_text @music_b_one.composer

    row = find("tr", text: @music_b_one.title)
    within row do
      click_on "Select"
    end

    assert_text "Music selection added successfully"
    assert_text "Prescribed"
    assert_text @music_b_one.title
  end

  test "season filter works on prescribed music index" do
    log_in_as(@admin)
    visit prescribed_music_index_url

    select @season.name, from: "Season"

    assert_text @music_one.title
    assert_no_text @archived_music.title
  end

  test "school class filter works on prescribed music index" do
    log_in_as(@admin)
    visit prescribed_music_index_url(season_id: @season.id)

    select @school_class.name, from: "School Class"

    assert_text @music_one.title
    assert_no_text @music_b_one.title
  end

  test "prescribed music search is case-insensitive" do
    log_in_as(@director_b)

    visit contest_url(@contest_c)
    click_on "Register"

    if page.has_select?("Large ensemble")
      select @ensemble_b.name, from: "Large ensemble"
    end

    click_on "Continue"
    click_on "Add Prescribed Music"

    assert_selector "form#prescribed_search_form"
    fill_in "search", with: "rhapsody"
    click_on "Search"

    assert_text "Rhapsody in Blue"
    assert_text "George Gershwin"
  end

  test "empty search returns all prescribed music for school class" do
    log_in_as(@director_b)

    visit contest_url(@contest_c)
    click_on "Register"

    if page.has_select?("Large ensemble")
      select @ensemble_b.name, from: "Large ensemble"
    end

    click_on "Continue"
    click_on "Add Prescribed Music"

    assert_selector "form#prescribed_search_form"
    fill_in "search", with: ""
    click_on "Search"

    assert_text "Rhapsody in Blue"
    assert_text "American in Paris"
    assert_text "Appalachian Spring"
    assert_text "West Side Story Suite"
    assert_text "Candide Overture"
  end

  test "prescribed music index redirects to current season when no season specified" do
    log_in_as(@admin)

    visit prescribed_music_index_url

    assert_current_path prescribed_music_index_path(season_id: @season.id)

    assert_text @music_one.title

    assert_no_text @archived_music.title
  end
end
