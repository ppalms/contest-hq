require "application_system_test_case"

class PrescribedMusicMultiAccountTest < ApplicationSystemTestCase
  setup do
    @demo_admin = users(:demo_admin_a)
    @customer_admin = users(:customer_admin_a)
    @customer_director = users(:customer_director_a)

    @demo_season = seasons(:demo_2025)
    @customer_season = seasons(:customer_2024)

    @demo_school_class = school_classes(:demo_school_class_a)
    @customer_school_class = school_classes(:customer_school_class_f)

    @customer_contest = contests(:customer_contest_a)
    @customer_ensemble = large_ensembles(:customer_school_a_ensemble_a)
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
    PrescribedMusic.create!(
      title: "Demo Symphony No. 1",
      composer: "Demo Composer A",
      season: @demo_season,
      school_class: @demo_school_class,
      account: @demo_admin.account
    )

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
    PrescribedMusic.create!(
      title: "Customer Concerto No. 1",
      composer: "Customer Composer A",
      season: @customer_season,
      school_class: @customer_school_class,
      account: @customer_admin.account
    )

    log_in_as(@demo_admin)
    visit prescribed_music_index_url

    assert_text "Prescribed Music"
    assert_no_text "Customer Concerto No. 1"
    assert_no_text "Customer Composer A"
  end

  test "customer director can view their account prescribed music" do
    # Create music for customer account
    PrescribedMusic.create!(
      title: "Customer Concerto No. 1",
      composer: "Customer Composer A",
      season: @customer_season,
      school_class: @customer_school_class,
      account: @customer_admin.account
    )

    log_in_as(@customer_director)
    visit prescribed_music_index_url

    assert_text "Prescribed Music"
    assert_text "Customer Concerto No. 1"
    assert_text "Customer Composer A"
  end

  test "customer director cannot see demo account prescribed music" do
    # Create music for demo account
    PrescribedMusic.create!(
      title: "Demo Symphony No. 1",
      composer: "Demo Composer A",
      season: @demo_season,
      school_class: @demo_school_class,
      account: @demo_admin.account
    )

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
    music = PrescribedMusic.create!(
      title: "Customer Concerto No. 2",
      composer: "Customer Composer B",
      season: @customer_season,
      school_class: @customer_school_class,
      account: @customer_admin.account
    )

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
    demo_music = PrescribedMusic.create!(
      title: "Demo Symphony No. 1",
      composer: "Demo Composer A",
      season: @demo_season,
      school_class: @demo_school_class,
      account: @demo_admin.account
    )

    customer_music = PrescribedMusic.create!(
      title: "Customer Concerto No. 1",
      composer: "Customer Composer A",
      season: @customer_season,
      school_class: @customer_school_class,
      account: @customer_admin.account
    )

    log_in_as(@customer_director)
    visit contest_url(@customer_contest)
    click_on "Register"

    if page.has_select?("Large ensemble")
      select @customer_ensemble.name, from: "Large ensemble"
    end

    click_on "Continue"
    click_on "Add Prescribed Music"

    # Search for music (should only find customer account music)
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
    music = PrescribedMusic.create!(
      title: "Customer Concerto No. 2",
      composer: "Customer Composer B",
      season: @customer_season,
      school_class: @customer_school_class,
      account: @customer_admin.account
    )

    log_in_as(@customer_director)
    visit contest_url(@customer_contest)
    click_on "Register"

    if page.has_select?("Large ensemble")
      select @customer_ensemble.name, from: "Large ensemble"
    end

    click_on "Continue"

    # Add prescribed music
    click_on "Add Prescribed Music"
    fill_in "search", with: "Concerto"
    click_on "Search"

    row = find("tr", text: "Customer Concerto No. 2")
    within row do
      click_on "Select"
    end

    assert_text "Music selection added successfully"

    # Add first custom music
    click_on "Add Custom Music"
    fill_in "Title", with: "Custom Piece No. 1"
    fill_in "Composer", with: "Custom Composer A"
    click_on "Add Music Selection"

    assert_text "Music selection added successfully"

    # Add second custom music
    click_on "Add Custom Music"
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
    demo_music1 = PrescribedMusic.create!(
      title: "Demo Symphony No. 1",
      composer: "Demo Composer A",
      season: @demo_season,
      school_class: @demo_school_class,
      account: @demo_admin.account
    )

    demo_music2 = PrescribedMusic.create!(
      title: "Demo Symphony No. 2",
      composer: "Demo Composer B",
      season: @demo_season,
      school_class: @demo_school_class,
      account: @demo_admin.account
    )

    customer_music1 = PrescribedMusic.create!(
      title: "Customer Concerto No. 1",
      composer: "Customer Composer A",
      season: @customer_season,
      school_class: @customer_school_class,
      account: @customer_admin.account
    )

    customer_music2 = PrescribedMusic.create!(
      title: "Customer Concerto No. 2",
      composer: "Customer Composer B",
      season: @customer_season,
      school_class: @customer_school_class,
      account: @customer_admin.account
    )

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
