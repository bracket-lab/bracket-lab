require "application_system_test_case"

class Admin::InvitesTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin_user)
  end

  test "admin can access bulk invite form" do
    sign_in_as(@admin)
    visit admin_invites_path
    click_on "Bulk Invite"
    assert_selector "h1", text: "Bulk Invite Users"
  end

  test "admin can preview valid bulk invites" do
    sign_in_as(@admin)
    visit bulk_new_admin_invites_path

    fill_in "bulk_invites", with: "John Smith <john@example.com>\nJane Doe <jane@example.com>"
    click_on "Preview Invites"

    assert_text "Valid Invites (2)"
    assert_text "John Smith"
    assert_text "jane@example.com"
  end

  test "admin can create new invite" do
    sign_in_as(@admin)
    visit admin_invites_path
    click_on "New Invite"

    fill_in "Email address", with: "newinvite@example.com"
    fill_in "Full name", with: "New Invitee"
    click_on "Send Invite"

    assert_text "Invitation sent successfully"
    assert_text "newinvite@example.com"
    assert_text "New Invitee"
  end

  test "shows validation errors on invalid invite creation" do
    sign_in_as(@admin)
    visit new_admin_invite_path

    fill_in "Email address", with: ""
    fill_in "Full name", with: ""
    click_on "Send Invite"

    assert_text "Email address can't be blank"
    assert_text "Full name can't be blank"
  end

  test "admin can see invalid entries in preview" do
    sign_in_as(@admin)
    visit bulk_new_admin_invites_path

    fill_in "bulk_invites", with: "Invalid Format\nJohn Smith <invalid-email>\nJane Doe <jane@example.com>"
    click_on "Preview Invites"

    assert_text "Invalid Entries (2)"
    assert_text "Invalid format"
    assert_text "Valid Invites (1)"
  end
end
