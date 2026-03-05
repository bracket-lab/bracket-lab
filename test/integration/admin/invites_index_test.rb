require "test_helper"

class Admin::InvitesIndexTest < ActionDispatch::IntegrationTest
  test "admin can view invites index" do
    sign_in_as(users(:admin_user))
    get admin_invites_path

    assert_response :success
    assert_select "h1", text: /Pending Invites/
    assert_select "a", text: "New Invite"
  end
end
