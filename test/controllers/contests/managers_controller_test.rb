require "test_helper"

class Contests::ManagersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @demo_admin = create(:user, :account_admin)
    set_current_user(@demo_admin)
    @demo_contest = create(:contest, account: @demo_admin.account)
    @demo_manager_a = create(:user, :manager, account: @demo_admin.account, first_name: "Nobby", last_name: "Nobbs")
    @demo_manager_b = create(:user, :manager, account: @demo_admin.account, first_name: "Samuel", last_name: "Vimes")
    @customer_admin = create(:user, :account_admin)
    create(:contest_manager, contest: @demo_contest, user: @demo_manager_a, account: @demo_admin.account)
  end

  test "new action only shows users with Manager role from current account" do
    sign_in_as(@demo_admin)

    get new_contest_manager_path(@demo_contest)
    assert_response :success

    assert_select "td", text: "#{@demo_manager_a.first_name} #{@demo_manager_a.last_name}"
    assert_select "td", text: "#{@demo_manager_b.first_name} #{@demo_manager_b.last_name}"

    assert_select "td", text: "#{@demo_admin.first_name} #{@demo_admin.last_name}", count: 0

    assert_select "td", text: "#{@customer_admin.first_name} #{@customer_admin.last_name}", count: 0
  end

  test "new action with search only shows managers matching search criteria" do
    sign_in_as(@demo_admin)

    get new_contest_manager_path(@demo_contest), params: { search: "Nobby" }
    assert_response :success

    assert_select "td", text: "#{@demo_manager_a.first_name} #{@demo_manager_a.last_name}"

    assert_select "td", text: "#{@demo_manager_b.first_name} #{@demo_manager_b.last_name}", count: 0
  end

  test "new action with search by email only shows managers matching email" do
    sign_in_as(@demo_admin)

    get new_contest_manager_path(@demo_contest), params: { search: @demo_manager_b.email }
    assert_response :success

    assert_select "td", text: "#{@demo_manager_b.first_name} #{@demo_manager_b.last_name}"

    assert_select "td", text: "#{@demo_manager_a.first_name} #{@demo_manager_a.last_name}", count: 0
  end

  test "index action only shows managers assigned to the contest" do
    sign_in_as(@demo_admin)

    get contest_managers_path(@demo_contest)
    assert_response :success

    assert_select "td", text: "#{@demo_manager_a.first_name} #{@demo_manager_a.last_name}"

    assert_select "td", text: "#{@demo_manager_b.first_name} #{@demo_manager_b.last_name}", count: 0

    assert_select "td", text: "#{@demo_admin.first_name} #{@demo_admin.last_name}", count: 0
  end

  test "cannot assign non-manager user as contest manager" do
    sign_in_as(@demo_admin)

    assert_no_difference "@demo_contest.managers.count" do
      post contest_managers_path(@demo_contest), params: {
        contest_manager: { user_id: @demo_admin.id }
      }
    end
  end

  test "can assign manager user to contest" do
    sign_in_as(@demo_admin)

    assert_difference "@demo_contest.managers.count", 1 do
      post contest_managers_path(@demo_contest), params: {
        contest_manager: { user_id: @demo_manager_b.id }
      }
    end

    assert_redirected_to contest_managers_path(@demo_contest)
    assert @demo_contest.managers.include?(@demo_manager_b)
  end

  test "cannot assign user from another account as contest manager" do
    sign_in_as(@demo_admin)

    assert_no_difference "@demo_contest.managers.count" do
      post contest_managers_path(@demo_contest), params: {
        contest_manager: { user_id: @customer_admin.id }
      }
    end

    assert_response :unprocessable_content
  end

  test "controller class exists and has required methods" do
    controller = Contests::ManagersController.new

    assert_respond_to controller, :index
    assert_respond_to controller, :new
    assert_respond_to controller, :create
    assert_respond_to controller, :destroy
  end
end
