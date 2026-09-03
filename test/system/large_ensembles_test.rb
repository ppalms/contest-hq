require "application_system_test_case"

class LargeEnsemblesTest < ApplicationSystemTestCase
  include LargeEnsemblesHelper

  setup do
    @director = create(:user, :director)
    set_current_user(@director)
    @performance_class = create(:performance_class, account: @director.account)
    @school = create(:school, account: @director.account)
    create(:school_director, user: @director, school: @school, account: @director.account)
    @large_ensemble = create(:large_ensemble, account: @director.account, name: "Concert Band", school: @school)
    log_in_as(@director)
  end

  test "should create large ensemble" do
    visit roster_large_ensembles_url
    click_on "New Large Ensemble"
    fill_in "Name", with: "Ultra Symphonic Band"
    select display_name_with_abbreviation(@performance_class), from: :performance_class_id
    select @school.name, from: :school_id
    click_on "Create Large Ensemble"

    assert_text "Large ensemble was successfully created"
    click_on "Large Ensembles"
    assert_text "Ultra Symphonic Band"
  end

  test "should update large ensemble" do
    visit roster_large_ensemble_url(@large_ensemble)
    click_on "Edit", match: :first

    assert_selector "form.wide-form"

    fill_in "Name", with: "New Large Ensemble Name"
    click_on "Update Large Ensemble"

    assert_text "Large ensemble was successfully updated"
    click_on "Large Ensemble"
    assert_text "New Large Ensemble Name"
  end

  test "should delete large ensemble" do
    visit roster_large_ensemble_url(@large_ensemble)
    click_on "Delete", match: :first

    accept_confirm

    assert_text "Large ensemble was successfully deleted"
    assert_no_text @large_ensemble.name
  end

  test "showing a large ensemble" do
    visit roster_large_ensembles_url
    click_on "View", match: :first

    assert_selector "h1", text: "Concert Band"
  end

  test "should only see own large ensemble" do
    visit roster_large_ensembles_url

    assert_no_text "Wind Ensemble"
  end
end
