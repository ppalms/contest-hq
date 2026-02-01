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

    if page.has_select?("Large ensemble")
      select @ensemble.name, from: "Large ensemble"
    end
    click_on "Continue"

    assert_text "Music Selections"

    click_on "Add Music"

    click_on "Select Prescribed Music"
    fill_in "search", with: "Symphony"
    click_on "Search"

    find("button", text: /Symphony No\. 5/).click

    assert_text "Prescribed"
    assert_text "New"
    assert_text "Symphony No. 5"

    within all("[data-slot-type='custom']").first do
      click_on "Add"
    end
    fill_in "Title", with: "Symphonic Dance No. 3"
    fill_in "Composer", with: "Williams"
    click_on "Add to List"

    within all("[data-slot-type='custom']").last do
      click_on "Add"
    end
    fill_in "Title", with: "Festive Overture"
    fill_in "Composer", with: "Shostakovich"
    click_on "Add to List"

    click_on "Save"

    assert_text "Symphony No. 5"
    assert_text "Symphonic Dance No. 3"
    assert_text "Festive Overture"
  end

  test "copying music from previous entry" do
    entry1 = ContestEntry.create!(contest: @contest, user: @user, large_ensemble: @ensemble_c, account: @user.account)
    entry1.music_selections.create!(title: "Symphony No. 5", composer: "Beethoven", prescribed_music: prescribed_musics(:demo_2024_class_a_music_one), account: @user.account)
    entry1.music_selections.create!(title: "Symphonic Dance No. 3", composer: "Williams", account: @user.account)
    entry1.music_selections.create!(title: "Festive Overture", composer: "Shostakovich", account: @user.account)

    contest2 = contests(:demo_contest_b)
    entry2 = ContestEntry.create!(contest: contest2, user: @user, large_ensemble: @ensemble_c, account: @user.account)

    visit contest_entry_path(contest_id: contest2.id, id: entry2.id)

    assert_text "Use music from previous entry?"
    assert_text "Symphony No. 5"
    assert_text "Symphonic Dance No. 3"
    assert_text "Festive Overture"

    click_on "Use These Pieces"

    assert_text "Symphony No. 5"
    assert_text "Symphonic Dance No. 3"
    assert_text "Festive Overture"
  end

  test "removing a music selection" do
    entry = ContestEntry.create!(contest: @contest, user: @user, large_ensemble: @ensemble_c, account: @user.account)
    entry.music_selections.create!(title: "Test Piece", composer: "Test Composer", account: @user.account)

    visit contest_entry_path(contest_id: @contest.id, id: entry.id)

    assert_text "Test Piece"

    within "#music_selections" do
      click_on "Edit"
    end

    click_on "Delete"

    click_on "Save"

    assert_no_text "Test Piece"
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

    # Verify we still have exactly 1 prescribed and 2 custom selections
    entry.reload
    assert_equal 3, entry.music_selections.count, "Should have exactly 3 music selections"
    assert_equal 1, entry.music_selections.where.not(prescribed_music_id: nil).count, "Should have exactly 1 prescribed selection"
    assert_equal 2, entry.music_selections.where(prescribed_music_id: nil).count, "Should have exactly 2 custom selections"

    # Verify the prescribed music was changed, not added
    assert_equal "The Planets", entry.prescribed_selection.title
  end

  test "deleting prescribed music" do
    entry = ContestEntry.create!(contest: @contest, user: @user, large_ensemble: @ensemble_c, account: @user.account)
    entry.music_selections.create!(title: "Symphony No. 5", composer: "Beethoven", prescribed_music: prescribed_musics(:demo_2024_class_a_music_one), position: 1, account: @user.account)
    entry.music_selections.create!(title: "Custom Piece 1", composer: "Composer 1", position: 2, account: @user.account)
    entry.music_selections.create!(title: "Custom Piece 2", composer: "Composer 2", position: 3, account: @user.account)

    visit contest_entry_path(contest_id: @contest.id, id: entry.id)

    within "#music_selections" do
      click_on "Edit"
    end

    # Delete prescribed music
    within "[data-prescribed='true']" do
      click_on "Delete"
    end

    # Verify "Undo" button appears
    within "[data-prescribed='true']" do
      assert_text "Undo"
    end

    # Save
    click_on "Save"

    # Verify prescribed music is removed
    entry.reload
    assert_nil entry.prescribed_selection, "Prescribed music should be deleted"
    assert_equal 2, entry.music_selections.count, "Should have 2 custom selections remaining"
  end

  test "undo delete prescribed music" do
    entry = ContestEntry.create!(contest: @contest, user: @user, large_ensemble: @ensemble_c, account: @user.account)
    entry.music_selections.create!(title: "Symphony No. 5", composer: "Beethoven", prescribed_music: prescribed_musics(:demo_2024_class_a_music_one), position: 1, account: @user.account)
    entry.music_selections.create!(title: "Custom Piece 1", composer: "Composer 1", position: 2, account: @user.account)
    entry.music_selections.create!(title: "Custom Piece 2", composer: "Composer 2", position: 3, account: @user.account)

    visit contest_entry_path(contest_id: @contest.id, id: entry.id)

    within "#music_selections" do
      click_on "Edit"
    end

    # Delete prescribed music
    within "[data-prescribed='true']" do
      click_on "Delete"
    end

    # Verify "Undo" button appears
    within "[data-prescribed='true']" do
      assert_text "Undo"
      click_on "Undo"
    end

    # Verify "Prescribed" badge restored
    within "[data-prescribed='true']" do
      assert_text "Prescribed"
      assert_text "Delete"
    end

    # Save
    click_on "Save"

    # Verify prescribed music still exists
    entry.reload
    assert_not_nil entry.prescribed_selection, "Prescribed music should still exist"
    assert_equal "Symphony No. 5", entry.prescribed_selection.title
    assert_equal 3, entry.music_selections.count, "Should have all 3 selections"
  end
end
