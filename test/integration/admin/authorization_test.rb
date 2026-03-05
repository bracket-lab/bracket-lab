require "test_helper"

class Admin::AuthorizationTest < ActionDispatch::IntegrationTest
  test "non-logged in users cannot access admin dashboard" do
    get admin_root_path
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "p", text: /log in/i
  end

  test "regular users cannot access admin dashboard" do
    sign_in_as(users(:user))
    get admin_root_path
    assert_redirected_to root_path
    follow_redirects!
    assert_select "div", text: /not authorized/i
  end

  test "non-admin users cannot access invites" do
    sign_in_as(users(:user))
    get admin_invites_path
    assert_redirected_to root_path
    follow_redirects!
    assert_select "div", text: /not authorized/i
  end

  private

  def follow_redirects!
    follow_redirect! while response.redirect?
  end
end
