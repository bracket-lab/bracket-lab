require "test_helper"

class NavigationIntegrationTest < ActionDispatch::IntegrationTest
  test "admin always sees tournament management link" do
    sign_in_as(users(:admin_user))
    get admin_root_path

    assert_response :success
    assert_select "a[href=?]", admin_tournament_path, text: "Tournament"
  end

  test "admin dashboard shows user and bracket counts" do
    sign_in_as(users(:admin_user))
    get admin_root_path

    assert_response :success
    # Use specific selectors for dashboard stats
    assert_select "dt", text: "Total Users"
    assert_select "dt", text: "Pending Invites"
  end
end
