require "application_system_test_case"

class MusicSelectionsTest < ApplicationSystemTestCase
  setup do
    @user = users(:demo_director_b)
    @entry = contest_entries(:contest_a_school_a_ensemble_b)
    @contest = @entry.contest

    # Clean up existing music selections
    set_current_user(@user)
    @entry.music_selections.destroy_all

    log_in_as(@user)
  end

  test "director can add custom music" do
    visit contest_entry_path(@contest, @entry)

    click_on "Add Custom Music"

    assert_text "Add Custom Music"

    fill_in "Title", with: "Symphony No. 5"
    fill_in "Composer", with: "Beethoven"

    click_on "Add Music Selection"

    assert_text "Music selection added successfully"
    assert_text "Symphony No. 5"
    assert_text "Beethoven"
  end

  test "director can add prescribed music" do
    visit contest_entry_path(@contest, @entry)

    click_on "Add Prescribed Music"

    assert_text "Select Prescribed Music"

    # Search for prescribed music
    fill_in "search", with: ""
    click_on "Search"

    # Should show prescribed music for the correct season/class
    assert_selector "table"

    # Select the first prescribed music
    first("button", text: "Select").click

    assert_text "Music selection added successfully"
  end

  test "director can edit custom music" do
    # Create a custom music selection first
    set_current_user(@user)
    selection = @entry.music_selections.create!(
      title: "Original Title",
      composer: "Original Composer",
      position: 1,
      account: @contest.account
    )

    visit contest_entry_path(@contest, @entry)

    within "#music_selections" do
      click_on "Edit"
    end

    assert_text "Edit Music Selection"

    fill_in "Title", with: "Updated Title"
    fill_in "Composer", with: "Updated Composer"

    click_on "Update Music Selection"

    assert_text "Music selection updated successfully"
    assert_text "Updated Title"
    assert_text "Updated Composer"
  end

  test "director can delete music selection" do
    # Create a music selection first
    set_current_user(@user)
    selection = @entry.music_selections.create!(
      title: "To Be Deleted",
      composer: "Test Composer",
      position: 1,
      account: @contest.account
    )

    visit contest_entry_path(@contest, @entry)

    assert_text "To Be Deleted"

    within "#music_selections" do
      accept_confirm do
        click_on "Delete"
      end
    end

    assert_text "Music selection removed"
    assert_no_text "To Be Deleted"
  end

  test "director sees empty state when no music selections" do
    visit contest_entry_path(@contest, @entry)

    # Should show music section with empty state or add buttons
    assert_text "Music Selections"
  end

  test "director can delete and readd music selection filling gaps" do
    # Create two selections (1 prescribed, 1 custom) - still need 1 more custom
    set_current_user(@user)
    prescribed = prescribed_musics(:demo_2024_class_a_music_one)
    @entry.music_selections.create!(prescribed_music: prescribed, position: 1, account: @contest.account)
    @entry.music_selections.create!(title: "Custom One", composer: "C1", position: 3, account: @contest.account)

    visit contest_entry_path(@contest, @entry)

    # Should show we need 1 more custom
    assert_text "1 custom needed"

    # Add a new one - should fill the gap at position 2
    click_on "Add Custom Music"

    fill_in "Title", with: "Custom Two"
    fill_in "Composer", with: "C2"

    click_on "Add Music Selection"

    assert_text "Music selection added successfully"
    assert_text "Custom Two"

    # Verify we have 3 selections and it's complete
    @entry.reload
    assert_equal 3, @entry.music_selections.count
    assert @entry.music_complete?

    # Verify the new selection filled position 2 (the gap)
    assert_equal 2, @entry.music_selections.find_by(title: "Custom Two").position
  end

  test "director can replace prescribed music with different prescribed music" do
    # Create a prescribed music selection first
    set_current_user(@user)
    old_prescribed = prescribed_musics(:demo_2024_class_a_music_one)
    selection = @entry.music_selections.create!(
      prescribed_music: old_prescribed,
      position: 1,
      account: @contest.account
    )

    visit contest_entry_path(@contest, @entry)

    assert_text old_prescribed.title

    within "#music_selections" do
      click_on "Edit"
    end

    assert_text "Edit Music Selection"
    assert_text "This is a prescribed music selection"

    click_on "Change to Different Prescribed Music"

    assert_text "Select Prescribed Music"

    # Search for prescribed music
    fill_in "search", with: ""
    click_on "Search"

    # Select a different prescribed music (not the first one)
    all("button", text: "Select").last.click

    assert_text "Music selection updated successfully"
    assert_no_text old_prescribed.title
  end
end
