require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @user = users(:user)
  end

  test "should get index when admin" do
    sign_in_as(@admin)
    get admin_users_url
    assert_response :success
  end

  test "should not get index when not admin" do
    sign_in_as(@user)
    get admin_users_url
    assert_redirected_to root_url
  end

  test "should get edit when admin" do
    sign_in_as(@admin)
    get edit_admin_user_url(@user)
    assert_response :success
  end

  test "should update user when admin" do
    sign_in_as(@admin)
    patch admin_user_url(@user), params: {
      user: {
        full_name: "Updated Name"
      }
    }
    assert_redirected_to admin_users_url
    @user.reload
    assert_equal "Updated Name", @user.full_name
  end

  test "should destroy user when admin" do
    sign_in_as(@admin)
    assert_difference("User.count", -1) do
      delete admin_user_url(@user)
    end
    assert_redirected_to admin_users_url
  end
end
