require "test_helper"

class SchoolClassTest < ActiveSupport::TestCase
  def setup
    set_current_user(users(:demo_admin_a))
  end

  test "should have many prescribed_musics" do
    school_class = school_classes(:demo_school_class_a)
    assert_respond_to school_class, :prescribed_musics
  end

  test "should restrict deletion if prescribed_musics exist" do
    school_class = school_classes(:demo_school_class_a)
    # Verify that this school class has prescribed music
    assert school_class.prescribed_musics.any?, "School class should have prescribed music for this test"

    assert_no_difference "SchoolClass.count" do
      school_class.destroy
    end
    assert_not school_class.destroyed?
    assert_includes school_class.errors[:base], "Cannot delete record because dependent prescribed musics exist"
  end

  test "should allow deletion if no prescribed_musics exist" do
    set_current_user(users(:customer_admin_a))
    school_class = school_classes(:customer_school_class_c)
    # Verify that this school class has no prescribed music
    assert school_class.prescribed_musics.empty?, "School class should have no prescribed music for this test"

    assert_difference "SchoolClass.count", -1 do
      school_class.destroy
    end
    assert school_class.destroyed?
  end
end
