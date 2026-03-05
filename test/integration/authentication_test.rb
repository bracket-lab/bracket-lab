require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
  end

  test "requires authentication" do
    get root_url
    assert_redirected_to new_session_path
  end

  test "allows access with valid session" do
    sign_in_as(@user)
    get root_url
    assert_redirected_to brackets_path
  end

  test "redirects to setup when no users exist" do
    # Delete all records in the correct order to handle foreign key constraints
    Session.delete_all
    Bracket.delete_all
    Invite.delete_all
    User.delete_all

    # First request will redirect to session/new due to require_authentication
    get root_url
    assert_redirected_to new_session_path

    # Follow the redirect and we should be redirected to setup
    follow_redirect!
    assert_redirected_to new_setup_path
  end

  test "maintains return to url after authentication" do
    get brackets_url
    assert_redirected_to new_session_path

    sign_in_as(@user)
    assert_redirected_to brackets_url
  end

  test "terminates session on sign out" do
    sign_in_as(@user)
    assert_difference "Session.count", -1 do
      delete session_url
    end
    assert_redirected_to new_session_path

    # Verify session is terminated
    get root_url
    assert_redirected_to new_session_path
  end

  test "creates new session with user agent and ip" do
    post session_url, params: {
      email_address: @user.email_address,
      password: "password"
    }, headers: {
      "HTTP_USER_AGENT" => "Test Browser",
      "REMOTE_ADDR" => "1.2.3.4"
    }

    session = Session.last
    assert_equal "Test Browser", session.user_agent
    assert_equal "1.2.3.4", session.ip_address
  end
end
