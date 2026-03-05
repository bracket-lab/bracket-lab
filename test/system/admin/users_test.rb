require "application_system_test_case"

class Admin::UsersTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin_user)
    @regular_user = users(:user)
  end

  test "admin can edit existing user" do
    sign_in_as(@admin)
    visit admin_users_path

    within "tr", text: @regular_user.email_address do
      click_on "Edit"
    end

    fill_in "Full name", with: "Updated Name"
    click_on "Update User"

    assert_text "User was successfully updated"
    assert_text "Updated Name"
  end
end
