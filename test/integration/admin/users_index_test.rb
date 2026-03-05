require "test_helper"

class Admin::UsersIndexTest < ActionDispatch::IntegrationTest
  test "admin can view users index" do
    sign_in_as(users(:admin_user))
    get admin_users_path

    assert_response :success
    assert_select "h1", text: /All Users/
    assert_select "td", text: users(:user).email_address
    assert_select "td", text: users(:admin_user).email_address
  end
end
