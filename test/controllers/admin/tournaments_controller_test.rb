require "test_helper"

class Admin::TournamentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
    sign_in_as(@user)
  end

  test "update_region_labels reorders labels" do
    new_order = [ "East", "West", "South", "Midwest" ]
    post update_region_labels_admin_tournament_path, params: { region_labels: new_order }

    assert_redirected_to admin_tournament_path
    assert_equal new_order, Tournament.field_64.reload.region_labels
  end

  test "update_region_labels rejects invalid permutation" do
    post update_region_labels_admin_tournament_path, params: { region_labels: [ "South", "South", "East", "Midwest" ] }

    assert_redirected_to admin_tournament_path
    assert_equal "Region labels must be a permutation of the four region names", flash[:alert]
  end
end
