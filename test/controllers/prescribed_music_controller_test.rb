require "test_helper"

class PrescribedMusicControllerTest < ActionDispatch::IntegrationTest
  setup do
    @prescribed_music = prescribed_musics(:demo_class_a_music_one)
    @admin = users(:demo_admin_a)
    @director = users(:demo_director_a)
  end

  test "should get index as admin" do
    sign_in_as(@admin)
    get prescribed_music_index_url
    assert_response :success
  end

  test "should get index as director" do
    sign_in_as(@director)
    get prescribed_music_index_url
    assert_response :success
  end

  test "should filter by season" do
    sign_in_as(@admin)
    get prescribed_music_index_url(season_id: seasons(:demo_2025).id)
    assert_response :success
    assert_select "h3", text: school_classes(:demo_school_class_a).name
  end

  test "should filter by school class" do
    sign_in_as(@admin)
    get prescribed_music_index_url(
      season_id: seasons(:demo_2025).id,
      school_class_id: school_classes(:demo_school_class_a).id
    )
    assert_response :success
  end

  test "should get new as admin" do
    sign_in_as(@admin)
    get new_prescribed_music_url
    assert_response :success
  end

  test "should not get new as director" do
    sign_in_as(@director)
    get new_prescribed_music_url
    assert_redirected_to prescribed_music_index_url
    assert_equal "You must be an account admin to perform this action.", flash[:alert]
  end

  test "should create prescribed_music as admin" do
    sign_in_as(@admin)
    assert_difference("PrescribedMusic.count") do
      post prescribed_music_index_url, params: {
        prescribed_music: {
          title: "New Symphony",
          composer: "New Composer",
          season_id: seasons(:demo_2025).id,
          school_class_id: school_classes(:demo_school_class_a).id
        }
      }
    end

    assert_redirected_to prescribed_music_index_url(season_id: seasons(:demo_2025).id)
  end

  test "should not create prescribed_music as director" do
    sign_in_as(@director)
    assert_no_difference("PrescribedMusic.count") do
      post prescribed_music_index_url, params: {
        prescribed_music: {
          title: "New Symphony",
          composer: "New Composer",
          season_id: seasons(:demo_2025).id,
          school_class_id: school_classes(:demo_school_class_a).id
        }
      }
    end

    assert_redirected_to prescribed_music_index_url
  end

  test "should get edit as admin" do
    sign_in_as(@admin)
    get edit_prescribed_music_url(@prescribed_music)
    assert_response :success
  end

  test "should not get edit as director" do
    sign_in_as(@director)
    get edit_prescribed_music_url(@prescribed_music)
    assert_redirected_to prescribed_music_index_url
  end

  test "should update prescribed_music as admin" do
    sign_in_as(@admin)
    patch prescribed_music_url(@prescribed_music), params: {
      prescribed_music: {
        title: "Updated Title"
      }
    }
    assert_redirected_to prescribed_music_index_url(season_id: @prescribed_music.season_id)
    @prescribed_music.reload
    assert_equal "Updated Title", @prescribed_music.title
  end

  test "should not update prescribed_music as director" do
    sign_in_as(@director)
    original_title = @prescribed_music.title
    patch prescribed_music_url(@prescribed_music), params: {
      prescribed_music: {
        title: "Updated Title"
      }
    }
    assert_redirected_to prescribed_music_index_url
    @prescribed_music.reload
    assert_equal original_title, @prescribed_music.title
  end

  test "should destroy prescribed_music as admin" do
    sign_in_as(@admin)
    assert_difference("PrescribedMusic.count", -1) do
      delete prescribed_music_url(@prescribed_music)
    end

    assert_redirected_to prescribed_music_index_url(season_id: @prescribed_music.season_id)
  end

  test "should not destroy prescribed_music as director" do
    sign_in_as(@director)
    assert_no_difference("PrescribedMusic.count") do
      delete prescribed_music_url(@prescribed_music)
    end

    assert_redirected_to prescribed_music_index_url
  end
end
