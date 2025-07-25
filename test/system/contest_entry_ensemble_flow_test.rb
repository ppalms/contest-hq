require "application_system_test_case"

class ContestEntryEnsembleFlowTest < ApplicationSystemTestCase
  include LargeEnsemblesHelper

  setup do
    @contest = contests(:demo_contest_a)
    @user_without_ensemble = users(:demo_director_c)
    # Ensure this user has no ensembles
    LargeEnsemble.where(id: @user_without_ensemble.conducted_ensembles.ids).destroy_all
  end

  test "should prompt to create ensemble when user has none" do
    log_in_as(@user_without_ensemble)

    visit new_contest_entry_path(contest_id: @contest.id)

    # Should be redirected to new ensemble form
    assert_current_path new_roster_large_ensemble_path(redirect_to_contest_entry: @contest.id)
    assert_text "You need to create a large ensemble before registering for a contest."
    assert_text "You need to create a large ensemble before you can register for the contest."

    # Fill out the ensemble form
    fill_in "Name", with: "Test Ensemble"
    select display_name_with_abbreviation(performance_classes(:demo_performance_class_a)), from: :performance_class_id
    select schools(:demo_school_a).name, from: :school_id
    click_on "Create Large Ensemble"

    # Should be redirected back to contest entry form with ensemble selected
    assert_current_path new_contest_entry_path(contest_id: @contest.id, large_ensemble_id: LargeEnsemble.find_by(name: "Test Ensemble").id)
    assert_text "Large ensemble was successfully created. Now you can register for the contest."
    assert_text "New Contest Entry"

    # The ensemble should be pre-selected
    assert_field "contest_entry_large_ensemble_id", with: LargeEnsemble.find_by(name: "Test Ensemble").id
  end
end
