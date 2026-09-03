require "application_system_test_case"

class PrescribedMusicMultiAccountTest < ApplicationSystemTestCase
  setup do
    @demo_account = create(:account, name: "Public Demo")
    @customer_account = create(:account, name: "Customer")
    @demo_admin = create(:user, :account_admin, account: @demo_account)
    @customer_admin = create(:user, :account_admin, account: @customer_account)
    @customer_director = create(:user, :director, account: @customer_account)

    @demo_season = create(:season, account: @demo_account, name: "2025", ordinal: 3)
    @customer_season = create(:season, account: @customer_account, name: "2024", ordinal: 1)

    @demo_school_class = create(:school_class, account: @demo_account, name: "1-A", ordinal: 1)
    @customer_school_class = create(:school_class, account: @customer_account, name: "6-A", ordinal: 6)

    @customer_contest = create(:contest, account: @customer_account, season: @customer_season)
    set_current_user(@customer_director)
    @customer_ensemble = create(:large_ensemble, account: @customer_account)
  end

  test "demo admin can create prescribed music for their account" do
    log_in_as(@demo_admin)
    visit prescribed_music_index_url

    assert_text "Prescribed Music"

    click_on "Add Prescribed Music"
    fill_in "Title", with: "Demo Symphony No. 1"
    fill_in "Composer", with: "Demo Composer A"
    select @demo_season.name, from: "Season"
    select @demo_school_class.name, from: "School class"
    click_on "Create"

    assert_text "Prescribed music was successfully created"
    assert_text "Demo Symphony No. 1"
    assert_text "Demo Composer A"
  end

  test "customer admin cannot see demo account prescribed music" do
    # Create music for demo account
    create(:prescribed_music, title: "Demo Symphony No. 1", composer: "Demo Composer A", season: @demo_season, school_class: @demo_school_class, account: @demo_admin.account)

    log_in_as(@customer_admin)
    visit prescribed_music_index_url

    assert_text "Prescribed Music"
    assert_no_text "Demo Symphony No. 1"
    assert_no_text "Demo Composer A"
  end

  test "customer admin can create prescribed music for their account" do
    log_in_as(@customer_admin)
    visit prescribed_music_index_url

    assert_text "Prescribed Music"

    click_on "Add Prescribed Music"
    fill_in "Title", with: "Customer Concerto No. 1"
    fill_in "Composer", with: "Customer Composer A"
    select @customer_season.name, from: "Season"
    select @customer_school_class.name, from: "School class"
    click_on "Create"

    assert_text "Prescribed music was successfully created"
    assert_text "Customer Concerto No. 1"
    assert_text "Customer Composer A"
  end

  test "demo admin cannot see customer account prescribed music" do
    # Create music for customer account
    create(:prescribed_music, title: "Customer Concerto No. 1", composer: "Customer Composer A", season: @customer_season, school_class: @customer_school_class, account: @customer_admin.account)

    log_in_as(@demo_admin)
    visit prescribed_music_index_url

    assert_text "Prescribed Music"
    assert_no_text "Customer Concerto No. 1"
    assert_no_text "Customer Composer A"
  end

  test "customer director can view their account prescribed music" do
    # Create music for customer account
    create(:prescribed_music, title: "Customer Concerto No. 1", composer: "Customer Composer A", season: @customer_season, school_class: @customer_school_class, account: @customer_admin.account)

    log_in_as(@customer_director)
    visit prescribed_music_index_url

    assert_text "Prescribed Music"
    assert_text "Customer Concerto No. 1"
    assert_text "Customer Composer A"
  end

  test "customer director cannot see demo account prescribed music" do
    # Create music for demo account
    create(:prescribed_music, title: "Demo Symphony No. 1", composer: "Demo Composer A", season: @demo_season, school_class: @demo_school_class, account: @demo_admin.account)

    log_in_as(@customer_director)
    visit prescribed_music_index_url

    assert_text "Prescribed Music"
    assert_no_text "Demo Symphony No. 1"
    assert_no_text "Demo Composer A"
  end

  test "director cannot see admin buttons on prescribed music page" do
    log_in_as(@customer_director)
    visit prescribed_music_index_url

    assert_text "Prescribed Music"
    assert_no_text "Add Prescribed Music"
  end

  test "director can search and select prescribed music for contest entry" do
    # Create prescribed music for customer account
    music = create(:prescribed_music, title: "Customer Concerto No. 2", composer: "Customer Composer B", season: @customer_season, school_class: @customer_school_class, account: @customer_admin.account)

    log_in_as(@customer_director)
    visit contest_url(@customer_contest)
    click_on "Register"

    # Select ensemble if the select box is present
    if page.has_select?("Large ensemble")
      select @customer_ensemble.name, from: "Large ensemble"
    end

    click_on "Continue"

    assert_text "Contest entry was successfully created"
    assert_text @customer_ensemble.name

    # Add prescribed music
    click_on "Add Prescribed Music"

    # Search for prescribed music
    assert_selector "form#prescribed_search_form"
    fill_in "search", with: "Concerto"
    click_on "Search"

    # Verify search results appear
    assert_text "Customer Concerto No. 2", wait: 5

    # Select the music
    row = find("tr", text: "Customer Concerto No. 2")
    within row do
      click_on "Select"
    end

    # Verify prescribed music was added
    assert_text "Music selection added successfully"
    assert_text "Prescribed"
    assert_text "Customer Concerto No. 2"
  end

  test "director search only returns their account prescribed music" do
    # Create music for both accounts
    demo_music = create(:prescribed_music, title: "Demo Symphony No. 1", composer: "Demo Composer A", season: @demo_season, school_class: @demo_school_class, account: @demo_admin.account)
    customer_music = create(:prescribed_music, title: "Customer Concerto No. 1", composer: "Customer Composer A", season: @customer_season, school_class: @customer_school_class, account: @customer_admin.account)

    log_in_as(@customer_director)
    visit contest_url(@customer_contest)
    click_on "Register"

    if page.has_select?("Large ensemble")
      select @customer_ensemble.name, from: "Large ensemble"
    end

    click_on "Continue"
    click_on "Add Prescribed Music"

    # Search for music (should only find customer account music)
    assert_selector "form#prescribed_search_form"
    fill_in "search", with: "No. 1"
    click_on "Search"

    # Verify only customer music appears
    assert_text "Customer Concerto No. 1", wait: 5
    assert_no_text "Demo Symphony No. 1"
  end

  test "director can add custom music to contest entry" do
    log_in_as(@customer_director)
    visit contest_url(@customer_contest)
    click_on "Register"

    if page.has_select?("Large ensemble")
      select @customer_ensemble.name, from: "Large ensemble"
    end

    click_on "Continue"

    assert_text "Contest entry was successfully created"

    # Add custom music
    click_on "Add Custom Music"

    assert_selector "form#custom_music_form"

    fill_in "Title", with: "Custom Piece No. 1"
    fill_in "Composer", with: "Custom Composer A"
    click_on "Add Music Selection"

    # Verify custom piece was added
    assert_text "Music selection added successfully"
    assert_text "Custom Piece No. 1"
    assert_text "Custom Composer A"
  end

  test "director can add multiple music selections to contest entry" do
    # Create prescribed music for customer account
    music = create(:prescribed_music, title: "Customer Concerto No. 2", composer: "Customer Composer B", season: @customer_season, school_class: @customer_school_class, account: @customer_admin.account)

    log_in_as(@customer_director)
    visit contest_url(@customer_contest)
    click_on "Register"

    if page.has_select?("Large ensemble")
      select @customer_ensemble.name, from: "Large ensemble"
    end

    click_on "Continue"

    # Add prescribed music
    click_on "Add Prescribed Music"

    assert_selector "form#prescribed_search_form"
    fill_in "search", with: "Concerto"
    click_on "Search"

    row = find("tr", text: "Customer Concerto No. 2")
    within row do
      click_on "Select"
    end

    assert_text "Music selection added successfully"

    # Add first custom music
    click_on "Add Custom Music"

    assert_selector "form#custom_music_form"

    fill_in "Title", with: "Custom Piece No. 1"
    fill_in "Composer", with: "Custom Composer A"
    click_on "Add Music Selection"

    assert_text "Music selection added successfully"

    # Add second custom music
    click_on "Add Custom Music"

    assert_selector "form#custom_music_form"

    fill_in "Title", with: "Custom Piece No. 2"
    fill_in "Composer", with: "Custom Composer B"
    click_on "Add Music Selection"

    # Verify all three selections are displayed
    assert_text "Music selection added successfully"
    assert_text "Customer Concerto No. 2"
    assert_text "Custom Piece No. 1"
    assert_text "Custom Piece No. 2"
  end

  test "multi-account isolation is maintained across all operations" do
    # Create music for both accounts
    demo_music1 = create(:prescribed_music, title: "Demo Symphony No. 1", composer: "Demo Composer A", season: @demo_season, school_class: @demo_school_class, account: @demo_admin.account)
    demo_music2 = create(:prescribed_music, title: "Demo Symphony No. 2", composer: "Demo Composer B", season: @demo_season, school_class: @demo_school_class, account: @demo_admin.account)
    customer_music1 = create(:prescribed_music, title: "Customer Concerto No. 1", composer: "Customer Composer A", season: @customer_season, school_class: @customer_school_class, account: @customer_admin.account)
    customer_music2 = create(:prescribed_music, title: "Customer Concerto No. 2", composer: "Customer Composer B", season: @customer_season, school_class: @customer_school_class, account: @customer_admin.account)

    # Verify demo admin sees only their music
    log_in_as(@demo_admin)
    visit prescribed_music_index_url
    assert_text "Demo Symphony No. 1"
    assert_text "Demo Symphony No. 2"
    assert_no_text "Customer Concerto No. 1"
    assert_no_text "Customer Concerto No. 2"

    click_on @demo_admin.first_name
    click_on "Sign out"

    # Verify customer admin sees only their music
    log_in_as(@customer_admin)
    visit prescribed_music_index_url
    assert_text "Customer Concerto No. 1"
    assert_text "Customer Concerto No. 2"
    assert_no_text "Demo Symphony No. 1"
    assert_no_text "Demo Symphony No. 2"

    click_on @customer_admin.first_name
    click_on "Sign out"

    # Verify customer director sees only their account music
    log_in_as(@customer_director)
    visit prescribed_music_index_url
    assert_text "Customer Concerto No. 1"
    assert_text "Customer Concerto No. 2"
    assert_no_text "Demo Symphony No. 1"
    assert_no_text "Demo Symphony No. 2"
  end
end
