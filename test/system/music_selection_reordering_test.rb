require "application_system_test_case"

class MusicSelectionReorderingTest < ApplicationSystemTestCase
  setup do
    @user = users(:demo_director_a)
    @contest = contests(:demo_contest_a)
    @ensemble = large_ensembles(:demo_school_a_ensemble_c)
    log_in_as(@user)

    # Create entry with all 3 selections
    @entry = ContestEntry.create!(
      contest: @contest,
      user: @user,
      large_ensemble: @ensemble,
      account: @user.account
    )

    # Add prescribed music at position 1
    @prescribed = @entry.music_selections.create!(
      title: "Symphony No. 5",
      composer: "Beethoven",
      prescribed_music: prescribed_musics(:demo_2024_class_a_music_one),
      position: 1,
      account: @user.account
    )

    # Add custom music at positions 2 and 3
    @custom1 = @entry.music_selections.create!(
      title: "Custom Piece 1",
      composer: "Composer 1",
      position: 2,
      account: @user.account
    )

    @custom2 = @entry.music_selections.create!(
      title: "Custom Piece 2",
      composer: "Composer 2",
      position: 3,
      account: @user.account
    )
  end

  test "moving prescribed music down from position 1 to 2" do
    visit contest_entry_path(@contest, @entry)

    within "#music_selections" do
      click_on "Edit"
    end

    # Find prescribed music item and click down arrow
    within "[data-prescribed='true']" do
      assert_text "Symphony No. 5"
      find("button[data-action='music-bulk-edit#moveDown']").click
    end

    # Wait a moment for DOM to update
    sleep 0.5

    # Save and verify persistence
    click_on "Save"

    @entry.reload
    prescribed = @entry.music_selections.find_by(prescribed_music_id: @prescribed.prescribed_music_id)
    assert_equal 2, prescribed.position, "Prescribed music should be at position 2"

    custom1 = @entry.music_selections.find_by(title: "Custom Piece 1")
    assert_equal 1, custom1.position, "Custom Piece 1 should be at position 1"
  end

  test "moving prescribed music down to position 3 and back up" do
    visit contest_entry_path(@contest, @entry)

    within "#music_selections" do
      click_on "Edit"
    end

    # Move down twice (1 → 2 → 3)
    within "[data-prescribed='true']" do
      find("button[data-action='music-bulk-edit#moveDown']").click
      sleep 0.3
      find("button[data-action='music-bulk-edit#moveDown']").click
      sleep 0.3
    end

    # Move back up (3 → 2)
    within "[data-prescribed='true']" do
      find("button[data-action='music-bulk-edit#moveUp']").click
      sleep 0.3
    end

    # Save and verify
    click_on "Save"

    @entry.reload
    prescribed = @entry.music_selections.find_by(prescribed_music_id: @prescribed.prescribed_music_id)
    assert_equal 2, prescribed.position
  end

  test "replacing prescribed music at position 2" do
    # Move prescribed to position 2 first
    @prescribed.update!(position: 2)
    @custom1.update!(position: 1)

    visit contest_entry_path(@contest, @entry)

    within "#music_selections" do
      click_on "Edit"
    end

    # Click "Change" button on prescribed music
    within "[data-prescribed='true']" do
      click_on "Change"
    end

    # Select different prescribed music
    fill_in "search", with: "Planets"
    click_on "Search"
    find("button", text: /The Planets/).click
    sleep 0.5

    # Save and verify
    click_on "Save"

    @entry.reload
    assert_equal 1, @entry.music_selections.where.not(prescribed_music_id: nil).count
    prescribed = @entry.prescribed_selection
    assert_equal "The Planets", prescribed.title
    assert_equal 2, prescribed.position, "Replaced prescribed music should maintain position 2"
  end



  test "adding prescribed music to empty slot at position 3" do
    # Create entry with only 2 custom pieces using a different contest
    contest_b = contests(:demo_contest_b)
    entry = ContestEntry.create!(
      contest: contest_b,
      user: @user,
      large_ensemble: @ensemble,
      account: @user.account
    )

    entry.music_selections.create!(
      title: "Custom Piece A",
      composer: "Composer A",
      position: 1,
      account: @user.account
    )

    entry.music_selections.create!(
      title: "Custom Piece B",
      composer: "Composer B",
      position: 2,
      account: @user.account
    )

    visit contest_entry_path(contest_b, entry)

    within "#music_selections" do
      click_on "Edit"
    end

    # The first empty slot needing prescribed should show "Select Prescribed Music"
    # Since we have 2 custom pieces, position 3 should be the prescribed slot
    within "[data-slot-position='3']" do
      assert_text "Prescribed"
      assert_text "Empty slot - required for this entry"
      click_on "Select Prescribed Music"
    end

    # Search and select prescribed music
    fill_in "search", with: "Symphony"
    click_on "Search"
    find("button", text: /Symphony No\. 5/).click
    sleep 0.5

    # Save and verify
    click_on "Save"
    sleep 1  # Wait for save to complete

    entry.reload
    prescribed = entry.prescribed_selection
    assert_not_nil prescribed, "Prescribed music should exist after save"
    assert_equal "Symphony No. 5", prescribed.title
    assert_equal 3, prescribed.position, "Prescribed music should be at position 3"
  end

  test "reorder after replacing prescribed music" do
    visit contest_entry_path(@contest, @entry)

    within "#music_selections" do
      click_on "Edit"
    end

    # Replace prescribed music
    within "[data-prescribed='true']" do
      click_on "Change"
    end

    fill_in "search", with: "Planets"
    click_on "Search"
    find("button", text: /The Planets/).click
    sleep 0.5

    # Now move it down to position 2
    within "[data-prescribed='true']" do
      find("button[data-action='music-bulk-edit#moveDown']").click
      sleep 0.3
    end

    # Save and verify
    click_on "Save"

    @entry.reload
    prescribed = @entry.prescribed_selection
    assert_equal "The Planets", prescribed.title
    assert_equal 2, prescribed.position
  end

  test "cancel without saving discards all changes" do
    visit contest_entry_path(@contest, @entry)

    within "#music_selections" do
      click_on "Edit"
    end

    # Move prescribed music to position 3
    within "[data-prescribed='true']" do
      find("button[data-action='music-bulk-edit#moveDown']").click
      find("button[data-action='music-bulk-edit#moveDown']").click
    end

    # Delete one custom piece
    within all("[data-music-bulk-edit-target='item']")[0] do
      click_on "Delete"
    end

    # Click Cancel
    click_on "Cancel"

    # Verify no changes were saved
    @entry.reload
    assert_equal 1, @entry.prescribed_selection.position, "Prescribed music should still be at position 1"
    assert_equal 3, @entry.music_selections.count, "All 3 selections should still exist"
  end

  test "mix multiple operations before save" do
    visit contest_entry_path(@contest, @entry)

    within "#music_selections" do
      click_on "Edit"
    end

    # Move prescribed music to position 2
    within "[data-prescribed='true']" do
      find("button[data-action='music-bulk-edit#moveDown']").click
    end

    # Delete custom piece at position 3
    items = all("[data-music-bulk-edit-target='item']")
    within items[2] do
      click_on "Delete"
    end

    # Add new custom piece
    within "[data-slot-type='custom']" do
      click_on "Add"
    end
    fill_in "Title", with: "New Custom Piece"
    fill_in "Composer", with: "New Composer"
    click_on "Add to List"

    # Move prescribed music to position 3
    within "[data-prescribed='true']" do
      find("button[data-action='music-bulk-edit#moveDown']").click
    end

    # Replace prescribed music
    within "[data-prescribed='true']" do
      click_on "Change"
    end
    fill_in "search", with: "Planets"
    click_on "Search"
    find("button", text: /The Planets/).click

    # Save all changes
    click_on "Save"

    # Verify all changes applied correctly
    @entry.reload
    assert_equal 1, @entry.music_selections.where.not(prescribed_music_id: nil).count, "Should have exactly 1 prescribed selection"
    prescribed = @entry.prescribed_selection
    assert_equal "The Planets", prescribed.title
    assert_equal 3, prescribed.position

    # Verify custom selections
    custom_selections = @entry.custom_selections
    assert_equal 2, custom_selections.count
    assert custom_selections.any? { |s| s.title == "New Custom Piece" }
  end
end
