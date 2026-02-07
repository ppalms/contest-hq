require "test_helper"

class Contests::ManagersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @demo_admin = users(:demo_admin_a)
    @demo_contest = contests(:demo_contest_a)
    @demo_manager_a = users(:demo_manager_a)
    @demo_manager_b = users(:demo_manager_b)
    @customer_admin = users(:customer_admin_a)
  end

  test "new action only shows users with Manager role from current account" do
    sign_in_as(@demo_admin)

    get new_contest_manager_path(@demo_contest)
    assert_response :success

    # Should show managers from the same account
    assert_select "td", text: "#{@demo_manager_a.first_name} #{@demo_manager_a.last_name}"
    assert_select "td", text: "#{@demo_manager_b.first_name} #{@demo_manager_b.last_name}"

    # Should NOT show account admins (even from the same account)
    assert_select "td", text: "#{@demo_admin.first_name} #{@demo_admin.last_name}", count: 0

    # Should NOT show users from other accounts
    assert_select "td", text: "#{@customer_admin.first_name} #{@customer_admin.last_name}", count: 0
  end

  test "new action with search only shows managers matching search criteria" do
    sign_in_as(@demo_admin)

    get new_contest_manager_path(@demo_contest), params: { search: "Nobby" }
    assert_response :success

    # Should show Nobby Nobbs (demo_manager_a)
    assert_select "td", text: "#{@demo_manager_a.first_name} #{@demo_manager_a.last_name}"

    # Should NOT show Samuel Vimes (demo_manager_b) - doesn't match search
    assert_select "td", text: "#{@demo_manager_b.first_name} #{@demo_manager_b.last_name}", count: 0
  end

  test "new action with search by email only shows managers matching email" do
    sign_in_as(@demo_admin)

    get new_contest_manager_path(@demo_contest), params: { search: "vimes@demo.org" }
    assert_response :success

    # Should show Samuel Vimes (demo_manager_b)
    assert_select "td", text: "#{@demo_manager_b.first_name} #{@demo_manager_b.last_name}"

    # Should NOT show Nobby Nobbs (demo_manager_a) - doesn't match search
    assert_select "td", text: "#{@demo_manager_a.first_name} #{@demo_manager_a.last_name}", count: 0
  end

  test "index action only shows managers assigned to the contest" do
    sign_in_as(@demo_admin)

    get contest_managers_path(@demo_contest)
    assert_response :success

    # Should show demo_manager_a who is assigned to demo_contest_a
    assert_select "td", text: "#{@demo_manager_a.first_name} #{@demo_manager_a.last_name}"

    # Should NOT show demo_manager_b who is assigned to a different contest
    assert_select "td", text: "#{@demo_manager_b.first_name} #{@demo_manager_b.last_name}", count: 0

    # Should NOT show account admins
    assert_select "td", text: "#{@demo_admin.first_name} #{@demo_admin.last_name}", count: 0
  end

  test "cannot assign non-manager user as contest manager" do
    sign_in_as(@demo_admin)

    # Try to assign an account admin (who doesn't have Manager role) to the contest
    assert_no_difference "@demo_contest.managers.count" do
      post contest_managers_path(@demo_contest), params: {
        contest_manager: { user_id: @demo_admin.id }
      }
    end
  end

  test "can assign manager user to contest" do
    sign_in_as(@demo_admin)

    # Assign a user with Manager role to the contest
    assert_difference "@demo_contest.managers.count", 1 do
      post contest_managers_path(@demo_contest), params: {
        contest_manager: { user_id: @demo_manager_b.id }
      }
    end

    assert_redirected_to contest_managers_path(@demo_contest)
    assert @demo_contest.managers.include?(@demo_manager_b)
  end

  test "controller class exists and has required methods" do
    controller = Contests::ManagersController.new

    # Check that controller responds to expected methods
    assert_respond_to controller, :index
    assert_respond_to controller, :new
    assert_respond_to controller, :create
    assert_respond_to controller, :destroy
  end
end
