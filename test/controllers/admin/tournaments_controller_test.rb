require "test_helper"

class Admin::TournamentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
    sign_in_as(@user)
  end

  test "update_region_labels reorders labels" do
    new_order = ["East", "West", "South", "Midwest"]
    post update_region_labels_admin_tournament_path, params: { region_labels: new_order }

    assert_redirected_to admin_tournament_path
    assert_equal new_order, Tournament.field_64.reload.region_labels
  end

  test "update_region_labels rejects invalid permutation" do
    post update_region_labels_admin_tournament_path, params: { region_labels: ["South", "South", "East", "Midwest"] }

    assert_redirected_to admin_tournament_path
    assert_equal "Region labels must be a permutation of the four region names", flash[:alert]
  end

  test "region order section visible when pre_selection" do
    Tournament.field_64.update_column(:state, Tournament.states[:pre_selection])
    get admin_tournament_path
    assert_response :success
    assert_select "h2", text: "Region Order"
  end

  test "region order section hidden when started" do
    Tournament.field_64.update_column(:state, Tournament.states[:in_progress])
    get admin_tournament_path
    assert_response :success
    assert_select "h2", text: "Region Order", count: 0
  end

  test "update_region_labels rejected when tournament started" do
    Tournament.field_64.update_column(:state, Tournament.states[:in_progress])
    original = Tournament.field_64.region_labels.dup

    post update_region_labels_admin_tournament_path, params: { region_labels: ["East", "West", "South", "Midwest"] }

    assert_redirected_to admin_tournament_path
    assert_equal "Cannot change region order after tournament has started", flash[:alert]
    assert_equal original, Tournament.field_64.reload.region_labels
  end
end
