require "test_helper"

class Admin::InvitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @user = users(:user)
  end

  test "should get index when admin" do
    sign_in_as(@admin)
    get admin_invites_url
    assert_response :success
  end

  test "should not get index when not admin" do
    sign_in_as(@user)
    get admin_invites_url
    assert_redirected_to root_url
  end

  test "should get new when admin" do
    sign_in_as(@admin)
    get new_admin_invite_url
    assert_response :success
  end

  test "should create invite when admin" do
    sign_in_as(@admin)
    assert_difference("Invite.count") do
      post admin_invites_url, params: {
        invite: {
          email_address: "test@example.com",
          full_name: "Test User"
        }
      }
    end
    assert_redirected_to admin_invites_url
  end

  test "should send email when creating invite" do
    sign_in_as(@admin)
    assert_emails 1 do
      post admin_invites_url, params: {
        invite: {
          email_address: "test@example.com",
          full_name: "Test User"
        }
      }
    end
  end

  test "should get bulk new when admin" do
    sign_in_as(@admin)
    get bulk_new_admin_invites_url
    assert_response :success
  end

  test "should not get bulk new when not admin" do
    sign_in_as(@user)
    get bulk_new_admin_invites_url
    assert_redirected_to root_url
  end

  test "should preview valid bulk invites" do
    sign_in_as(@admin)
    post bulk_preview_admin_invites_url, params: {
      bulk_invites: "John Smith <john@example.com>\nJane Doe <jane@example.com>"
    }
    assert_response :success
    assert_select ".valid-invites", count: 1
  end

  test "should handle invalid bulk invites" do
    sign_in_as(@admin)
    post bulk_preview_admin_invites_url, params: {
      bulk_invites: "Invalid Format\nJohn Smith <invalid-email>"
    }
    assert_response :success
    assert_select ".invalid-invites", count: 1
  end

  test "should create multiple invites from bulk creation" do
    sign_in_as(@admin)
    assert_difference("Invite.count", 2) do
      post bulk_create_admin_invites_url, params: {
        invites: [
          { email: "john@example.com", name: "John Smith" },
          { email: "jane@example.com", name: "Jane Doe" }
        ]
      }
    end
    assert_redirected_to admin_invites_url
  end

  test "should send emails for bulk invites" do
    sign_in_as(@admin)
    assert_emails 2 do
      post bulk_create_admin_invites_url, params: {
        invites: [
          { email: "john@example.com", name: "John Smith" },
          { email: "jane@example.com", name: "Jane Doe" }
        ]
      }
    end
  end

  test "should destroy pending invite" do
    sign_in_as(@admin)
    assert_difference("Invite.count", -1) do
      delete admin_invite_url(invites(:pending))
    end
    assert_redirected_to admin_invites_url
    assert_equal "Invite was successfully deleted.", flash[:notice]
  end

  test "should not destroy non-pending invite" do
    sign_in_as(@admin)
    delete admin_invite_url(invites(:used_invite))
    assert_redirected_to admin_invites_url
    assert_equal "Only pending invites can be deleted.", flash[:alert]
  end

  test "should update payment_credits on invite" do
    sign_in_as(@admin)
    invite = invites(:valid_invite)
    patch admin_invite_url(invite), params: { invite: { payment_credits: 3 } }
    assert_redirected_to admin_invites_url
    invite.reload
    assert_equal 3, invite.payment_credits
  end
end
