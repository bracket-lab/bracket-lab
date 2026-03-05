require "test_helper"

class SetupControllerTest < ActionDispatch::IntegrationTest
  test "redirects to root if users exist" do
    get new_setup_url
    assert_redirected_to root_url
  end
end
