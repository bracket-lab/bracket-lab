require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    sign_in_as users(:user)
  end

  test "should get rules" do
    get rules_url
    assert_response :success
  end

  test "should redirect to root if accessing countdown when tournament is set" do
    Tournament.field_64.set_teams!

    get countdown_url
    assert_redirected_to root_path
  end
end
