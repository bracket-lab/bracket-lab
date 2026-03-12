require "test_helper"

class Admin::TeamsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @user = users(:user)
    @team = teams(:team_64)
  end

  test "should get index when admin" do
    sign_in_as(@admin)
    get admin_teams_url
    assert_response :success
  end

  test "should not get index when not admin" do
    sign_in_as(@user)
    get admin_teams_url
    assert_redirected_to root_url
  end

  test "should update team name" do
    sign_in_as(@admin)
    patch admin_team_url(@team), params: { team: { name: "New Name" } }, as: :turbo_stream
    assert_response :success
    @team.reload
    assert_equal "New Name", @team.name
  end

  test "should reject invalid team name" do
    sign_in_as(@admin)
    patch admin_team_url(@team), params: { team: { name: "This Name Is Way Too Long" } }, as: :turbo_stream
    assert_response :unprocessable_entity
    @team.reload
    assert_not_equal "This Name Is Way Too Long", @team.name
  end

  test "should reject duplicate team name" do
    sign_in_as(@admin)
    other_team = teams(:team_65)
    patch admin_team_url(@team), params: { team: { name: other_team.name } }, as: :turbo_stream
    assert_response :unprocessable_entity
  end
end
