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

  test "should reject blank team name" do
    sign_in_as(@admin)
    patch admin_team_url(@team), params: { team: { name: "" } }, as: :turbo_stream
    assert_response :unprocessable_entity
    @team.reload
    assert_equal "Auburn", @team.name
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

  test "should get import page" do
    sign_in_as(@admin)
    get import_admin_teams_url
    assert_response :success
  end

  test "import_preview validates exactly 64 teams" do
    sign_in_as(@admin)
    post import_preview_admin_teams_url, params: { team_names: "Team1\nTeam2\nTeam3" }
    assert_response :unprocessable_entity
  end

  test "import_preview validates name length" do
    sign_in_as(@admin)
    names = (1..64).map { |i| i == 1 ? "A" * 16 : "Team #{i}" }.join("\n")
    post import_preview_admin_teams_url, params: { team_names: names }
    assert_response :unprocessable_entity
  end

  test "import_preview validates unique names" do
    sign_in_as(@admin)
    names = ([ "Duplicate" ] * 2 + (3..64).map { |i| "Team #{i}" }).join("\n")
    post import_preview_admin_teams_url, params: { team_names: names }
    assert_response :unprocessable_entity
  end

  test "import_preview succeeds with valid input" do
    sign_in_as(@admin)
    names = (1..64).map { |i| "Team #{i}" }.join("\n")
    post import_preview_admin_teams_url, params: { team_names: names }
    assert_response :success
  end

  test "import_apply updates all 64 team names" do
    sign_in_as(@admin)
    new_names = (1..64).map { |i| "New #{i}" }
    post import_apply_admin_teams_url, params: { names: new_names }
    assert_redirected_to admin_teams_url
    Team.order(:starting_slot).each_with_index do |team, i|
      assert_equal "New #{i + 1}", team.name
    end
  end
end
