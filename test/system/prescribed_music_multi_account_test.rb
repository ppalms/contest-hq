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

  test "multi-account prescribed music isolation and director workflow" do
    # Step 1: Demo admin (Account A) creates three prescribed music selections
    log_in_as(@demo_admin)
    visit prescribed_music_index_url

    assert_text "Prescribed Music"

    # Create first prescribed music for demo account
    click_on "Add Prescribed Music"
    fill_in "Title", with: "Demo Symphony No. 1"
    fill_in "Composer", with: "Demo Composer A"
    select @demo_season.name, from: "Season"
    select @demo_school_class.name, from: "School class"
    click_on "Create"

    assert_text "Prescribed music was successfully created"
    assert_text "Demo Symphony No. 1"

    # Create second prescribed music for demo account
    click_on "Add Prescribed Music"
    fill_in "Title", with: "Demo Symphony No. 2"
    fill_in "Composer", with: "Demo Composer B"
    select @demo_season.name, from: "Season"
    select @demo_school_class.name, from: "School class"
    click_on "Create"

    assert_text "Prescribed music was successfully created"
    assert_text "Demo Symphony No. 2"

    # Create third prescribed music for demo account
    click_on "Add Prescribed Music"
    fill_in "Title", with: "Demo Symphony No. 3"
    fill_in "Composer", with: "Demo Composer C"
    select @demo_season.name, from: "Season"
    select @demo_school_class.name, from: "School class"
    click_on "Create"

    assert_text "Prescribed music was successfully created"
    assert_text "Demo Symphony No. 3"

    # Verify all three demo pieces are visible
    assert_text "Demo Symphony No. 1"
    assert_text "Demo Symphony No. 2"
    assert_text "Demo Symphony No. 3"

    # Sign out
    click_on @demo_admin.first_name
    click_on "Sign out"

    # Step 2: Customer admin (Account B) creates three different prescribed music selections
    log_in_as(@customer_admin)
    visit prescribed_music_index_url

    assert_text "Prescribed Music"

    # Verify demo account music is NOT visible
    assert_no_text "Demo Symphony No. 1"
    assert_no_text "Demo Symphony No. 2"
    assert_no_text "Demo Symphony No. 3"

    # Create first prescribed music for customer account
    click_on "Add Prescribed Music"
    fill_in "Title", with: "Customer Concerto No. 1"
    fill_in "Composer", with: "Customer Composer A"
    select @customer_season.name, from: "Season"
    select @customer_school_class.name, from: "School class"
    click_on "Create"

    assert_text "Prescribed music was successfully created"
    assert_text "Customer Concerto No. 1"

    # Create second prescribed music for customer account
    click_on "Add Prescribed Music"
    fill_in "Title", with: "Customer Concerto No. 2"
    fill_in "Composer", with: "Customer Composer B"
    select @customer_season.name, from: "Season"
    select @customer_school_class.name, from: "School class"
    click_on "Create"

    assert_text "Prescribed music was successfully created"
    assert_text "Customer Concerto No. 2"

    # Create third prescribed music for customer account
    click_on "Add Prescribed Music"
    fill_in "Title", with: "Customer Concerto No. 3"
    fill_in "Composer", with: "Customer Composer C"
    select @customer_season.name, from: "Season"
    select @customer_school_class.name, from: "School class"
    click_on "Create"

    assert_text "Prescribed music was successfully created"
    assert_text "Customer Concerto No. 3"

    # Verify all three customer pieces are visible
    assert_text "Customer Concerto No. 1"
    assert_text "Customer Concerto No. 2"
    assert_text "Customer Concerto No. 3"

    # Verify demo account music is still NOT visible
    assert_no_text "Demo Symphony No. 1"
    assert_no_text "Demo Symphony No. 2"
    assert_no_text "Demo Symphony No. 3"

    # Sign out
    click_on @customer_admin.first_name
    click_on "Sign out"

    # Step 3: Customer director (Account B) views prescribed music list
    log_in_as(@customer_director)
    visit prescribed_music_index_url

    assert_text "Prescribed Music"

    # Verify only customer account music is visible
    assert_text "Customer Concerto No. 1"
    assert_text "Customer Concerto No. 2"
    assert_text "Customer Concerto No. 3"

    # Verify demo account music is NOT visible
    assert_no_text "Demo Symphony No. 1"
    assert_no_text "Demo Symphony No. 2"
    assert_no_text "Demo Symphony No. 3"

    # Verify director cannot see admin buttons
    assert_no_text "Add Prescribed Music"

    # Step 4: Director navigates to contest and registers
    visit contest_url(@customer_contest)
    click_on "Register"

    # Select ensemble if the select box is present
    # (it might be auto-selected if there's only one eligible ensemble)
    if page.has_select?("Large ensemble")
      select @customer_ensemble.name, from: "Large ensemble"
    end

    click_on "Continue"

    assert_text "Contest entry was successfully created"
    assert_text @customer_ensemble.name

    # Step 5: Add one prescribed music selection
    click_on "Add Music Selection"

    # Verify we're on the add music page with both sections
    assert_text "Add Music Selection"
    assert_text "Prescribed Music"
    assert_text "Custom Music"

    # Search for prescribed music
    fill_in "search", with: "Concerto"
    click_on "Search"

    # Verify search results appear
    assert_text "Customer Concerto No. 1"
    assert_text "Customer Concerto No. 2"
    assert_text "Customer Concerto No. 3"

    # Select Customer Concerto No. 2
    within ".prescribed-music-list" do
      # Find the button that contains "Customer Concerto No. 2" and click it
      click_on class: "prescribed-music-item", text: "Customer Concerto No. 2", match: :first
    end

    assert_text "Prescribed music was added to your contest entry"
    assert_text "Customer Concerto No. 2"
    assert_text "Prescribed Music"

    # Step 6: Add first custom music selection
    click_on "Add Music Selection"

    # Enter custom music (skip prescribed music section)
    within ".custom-music-section" do
      fill_in "Title", with: "Custom Piece No. 1"
      fill_in "Composer", with: "Custom Composer A"
      click_on "Save"
    end

    assert_text "Music selection added to contest entry"
    assert_text "Custom Piece No. 1"
    assert_text "Custom Composer A"

    # Step 7: Add second custom music selection
    click_on "Add Music Selection"

    within ".custom-music-section" do
      fill_in "Title", with: "Custom Piece No. 2"
      fill_in "Composer", with: "Custom Composer B"
      click_on "Save"
    end

    assert_text "Music selection added to contest entry"
    assert_text "Custom Piece No. 2"
    assert_text "Custom Composer B"

    # Step 8: Verify all three selections are displayed
    assert_text "Customer Concerto No. 2"
    assert_text "Custom Piece No. 1"
    assert_text "Custom Piece No. 2"

    # Verify prescribed music badge is only on the prescribed selection
    within "li", text: "Customer Concerto No. 2" do
      assert_text "Prescribed Music"
    end

    # Verify custom selections don't have the prescribed badge
    within "li", text: "Custom Piece No. 1" do
      assert_no_text "Prescribed Music"
    end

    within "li", text: "Custom Piece No. 2" do
      assert_no_text "Prescribed Music"
    end

    # Step 9: Verify contest entry is successfully registered
    assert_text @customer_ensemble.name
    assert_text @customer_contest.name

    # Verify we can navigate back to the contest and see the entry
    visit contest_url(@customer_contest)
    assert_text @customer_ensemble.name
  end
end
