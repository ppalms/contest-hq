require "application_system_test_case"

class MusicSelectionsTest < ApplicationSystemTestCase
  setup do
    @user = users(:demo_director_a)
    @contest = contests(:demo_contest_a)
    @ensemble = large_ensembles(:demo_school_a_ensemble_a)
    @ensemble_c = large_ensembles(:demo_school_a_ensemble_c)
    log_in_as(@user)
  end

  test "adding music selections to a new contest entry" do
    visit contest_path(@contest)
    click_on "Register"

    select @ensemble.name, from: "Large ensemble"
    click_on "Create Contest entry"

    assert_text "Music Selections"
    assert_text "0/3 pieces selected"

    click_on "Select Prescribed Music"
    fill_in "search", with: "March"
    click_on "Search"

    within "button", text: "March Grandioso" do
      click_on "March Grandioso"
    end

    assert_text "1/3 pieces selected"
    assert_text "March Grandioso"

    within "#music_slot_custom_1" do
      click_on "Add Custom Music"
    end

    fill_in "Title", with: "Symphonic Dance No. 3"
    fill_in "Composer", with: "Williams"
    click_on "Save"

    assert_text "2/3 pieces selected"
    assert_text "Symphonic Dance No. 3"

    within "#music_slot_custom_2" do
      click_on "Add Custom Music"
    end

    fill_in "Title", with: "Festive Overture"
    fill_in "Composer", with: "Shostakovich"
    click_on "Save"

    assert_text "✓ Complete (3/3 pieces selected)"
    assert_text "Festive Overture"
  end

  test "copying music from previous entry" do
    entry1 = ContestEntry.create!(contest: @contest, user: @user, large_ensemble: @ensemble_c, account: @user.account)
    entry1.music_selections.create!(title: "March Grandioso", composer: "Seitz", prescribed_music: prescribed_musics(:demo_class_a_music_one), account: @user.account)
    entry1.music_selections.create!(title: "Symphonic Dance No. 3", composer: "Williams", account: @user.account)
    entry1.music_selections.create!(title: "Festive Overture", composer: "Shostakovich", account: @user.account)

    contest2 = contests(:demo_contest_b)
    entry2 = ContestEntry.create!(contest: contest2, user: @user, large_ensemble: @ensemble_c, account: @user.account)

    visit contest_entry_path(contest_id: contest2.id, id: entry2.id)

    assert_text "Use music from previous entry?"
    assert_text "March Grandioso"
    assert_text "Symphonic Dance No. 3"
    assert_text "Festive Overture"

    click_on "Use These Pieces"

    assert_text "✓ Complete (3/3 pieces selected)"
    assert_text "March Grandioso"
    assert_text "Symphonic Dance No. 3"
    assert_text "Festive Overture"
  end

  test "removing a music selection" do
    entry = ContestEntry.create!(contest: @contest, user: @user, large_ensemble: @ensemble_c, account: @user.account)
    entry.music_selections.create!(title: "Test Piece", composer: "Test Composer", account: @user.account)

    visit contest_entry_path(contest_id: @contest.id, id: entry.id)

    assert_text "Test Piece"

    accept_confirm do
      click_on "Remove"
    end

    assert_no_text "Test Piece"
    assert_text "0/3 pieces selected"
  end

  test "bulk edit enforces music selection constraints" do
    entry = ContestEntry.create!(contest: @contest, user: @user, large_ensemble: @ensemble_c, account: @user.account)

    visit contest_entry_path(contest_id: @contest.id, id: entry.id)

    within "#music_selections" do
      click_on "Edit"
    end

    # Add prescribed music
    click_on "Select Prescribed Music"
    fill_in "search", with: "Symphony"
    click_on "Search"

    # Find and click the button containing "Symphony No. 5"
    find("button", text: /Symphony No\. 5/).click

    # Verify prescribed music appears with "New" badge
    assert_text "Prescribed"
    assert_text "New"
    assert_text "Symphony No. 5"

    # Add two custom selections
    within all("[data-slot-type='custom']").first do
      click_on "Add"
    end
    fill_in "Title", with: "Custom Piece 1"
    fill_in "Composer", with: "Composer 1"
    click_on "Add to List"

    within all("[data-slot-type='custom']").last do
      click_on "Add"
    end
    fill_in "Title", with: "Custom Piece 2"
    fill_in "Composer", with: "Composer 2"
    click_on "Add to List"

    # Save all selections
    click_on "Save"

    # Wait for save to complete by checking for the completion indicator
    assert_text "✓ Complete (3/3 pieces selected)"

    # Verify all saved
    entry.reload
    assert_equal 3, entry.music_selections.count
    assert_equal 1, entry.music_selections.where.not(prescribed_music_id: nil).count
    assert_equal 2, entry.music_selections.where(prescribed_music_id: nil).count

    # Now change the prescribed music
    within "#music_selections" do
      click_on "Edit"
    end

    within "[data-prescribed='true']" do
      click_on "Change"
    end

    fill_in "search", with: "Planets"
    click_on "Search"

    # Find and click the button containing "The Planets"
    find("button", text: /The Planets/).click

    # Verify new prescribed music appears
    assert_text "The Planets"
    assert_text "New"

    # Save the change
    click_on "Save"

    # Wait for save to complete
    assert_text "✓ Complete (3/3 pieces selected)"

    # Verify we still have exactly 1 prescribed and 2 custom selections
    entry.reload
    assert_equal 3, entry.music_selections.count, "Should have exactly 3 music selections"
    assert_equal 1, entry.music_selections.where.not(prescribed_music_id: nil).count, "Should have exactly 1 prescribed selection"
    assert_equal 2, entry.music_selections.where(prescribed_music_id: nil).count, "Should have exactly 2 custom selections"

    # Verify the prescribed music was changed, not added
    assert_equal "The Planets", entry.prescribed_selection.title
  end
end
