require "test_helper"

class InviteAcceptancesIntegrationTest < ActionDispatch::IntegrationTest
  test "visiting invite acceptance page shows welcome message" do
    invite = invites(:pending)
    get new_invite_acceptance_path(token: invite.token)

    assert_response :success
    assert_select "body", text: /Welcome #{invite.full_name}/
  end

  test "handles invalid token" do
    get new_invite_acceptance_path(token: "invalid")

    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "body", text: /Invalid or missing invite token/
  end

  test "handles expired invite" do
    invite = invites(:expired_invite)
    get new_invite_acceptance_path(token: invite.token)

    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "body", text: /expired/i
  end

  test "handles already used invite" do
    invite = invites(:used_invite)
    get new_invite_acceptance_path(token: invite.token)

    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "body", text: /already been used/i
  end

  test "shows password mismatch error on create" do
    invite = invites(:pending)

    post invite_acceptances_path(token: invite.token), params: {
      user: {
        password: "securepassword123",
        password_confirmation: "differentpassword"
      }
    }

    # Should redirect back with error
    assert_redirected_to new_invite_acceptance_path(token: invite.token)
    follow_redirect!
    assert_select "body", text: /passwords match/i
  end

  test "successful invite acceptance creates user and marks invite used" do
    # Create a fresh invite with unique email to avoid fixture conflicts
    invite = Invite.create!(
      email_address: "newuser_#{SecureRandom.hex(4)}@example.com",
      full_name: "New Test User",
      token: SecureRandom.hex(16),
      expires_at: 7.days.from_now,
      created_by: users(:admin_user)
    )
    assert_nil invite.used_at, "Invite should not be used yet"

    post invite_acceptances_path(token: invite.token), params: {
      user: {
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }
    }

    assert_redirected_to root_path
    invite.reload
    assert_not_nil invite.used_at, "Invite should be marked as used"
    assert User.exists?(email_address: invite.email_address), "User should be created"
  end
end
