require "test_helper"

class SchoolClassTest < ActiveSupport::TestCase
  def setup
    set_current_user(create(:user, :account_admin))
  end

  test "should have many prescribed_musics" do
    school_class = create(:school_class)
    assert_respond_to school_class, :prescribed_musics
  end

  test "should restrict deletion if prescribed_musics exist" do
    school_class = create(:school_class)
    create(:prescribed_music, school_class: school_class, account: school_class.account)

    assert school_class.prescribed_musics.any?, "School class should have prescribed music for this test"

    assert_no_difference "SchoolClass.count" do
      school_class.destroy
    end
    assert_not school_class.destroyed?
    assert_includes school_class.errors[:base], "Cannot delete record because dependent prescribed musics exist"
  end

  test "should allow deletion if no prescribed_musics exist" do
    school_class = create(:school_class)
    assert school_class.prescribed_musics.empty?, "School class should have no prescribed music for this test"

    assert_difference "SchoolClass.count", -1 do
      school_class.destroy
    end
    assert school_class.destroyed?
  end
end
