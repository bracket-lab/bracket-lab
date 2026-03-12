require "application_system_test_case"

class Admin::TeamsTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin_user)
  end

  test "admin can edit a team name inline" do
    sign_in_as(@admin)
    visit admin_teams_path

    team = teams(:team_64)
    within "#team_#{team.id}" do
      click_on "Edit"
      fill_in "team[name]", with: "Updated"
      click_on "Save"
    end

    within "#team_#{team.id}" do
      assert_text "Updated"
      assert_no_field "team[name]"
    end
    team.reload
    assert_equal "Updated", team.name
  end

  test "admin can access import page" do
    sign_in_as(@admin)
    visit admin_teams_path
    click_on "Import Teams"
    assert_selector "h1", text: "Import Teams"
  end

  test "admin can preview and apply import" do
    sign_in_as(@admin)
    visit import_admin_teams_path

    names = (1..64).map { |i| "Import #{i}" }.join("\n")
    fill_in "team_names", with: names
    click_on "Preview"

    assert_text "Preview Import"
    assert_text "Import 1"
    click_on "Apply All"

    assert_text "All 64 team names updated"
    assert_equal "Import 1", Team.order(:starting_slot).first.name
  end

  test "import shows errors for wrong count" do
    sign_in_as(@admin)
    visit import_admin_teams_path

    fill_in "team_names", with: "Only One Team"
    click_on "Preview"

    assert_text "Expected 64 team names, got 1"
  end
end
