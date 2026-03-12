require "application_system_test_case"

class Admin::TournamentRegionOrderTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin_user)
  end

  test "admin can reorder regions with dropdowns and save" do
    sign_in_as(@admin)
    visit admin_tournament_path

    click_on "Edit"

    # Swap positions 1 and 2 using the select dropdowns
    selects = all("select[name='region_labels[]']")
    selects[0].select "West"
    selects[1].select "South"

    click_on "Save"

    assert_text "Region order updated"
    assert_equal [ "West", "South", "East", "Midwest" ], Tournament.field_64.reload.region_labels
  end

  test "save rejects duplicate labels" do
    sign_in_as(@admin)
    visit admin_tournament_path

    click_on "Edit"

    selects = all("select[name='region_labels[]']")
    selects[0].select "East"
    # Now East appears in both position 1 and 3

    click_on "Save"

    assert_text "must be a permutation of the four region names"
    # Original order unchanged
    assert_equal [ "South", "West", "East", "Midwest" ], Tournament.field_64.reload.region_labels
  end

  test "cancel returns to show view without saving" do
    original = Tournament.field_64.region_labels.dup
    sign_in_as(@admin)
    visit admin_tournament_path

    click_on "Edit"
    selects = all("select[name='region_labels[]']")
    selects[0].select "Midwest"

    click_on "Cancel"

    assert_equal original, Tournament.field_64.reload.region_labels
    assert_text original.join(", ")
  end
end
