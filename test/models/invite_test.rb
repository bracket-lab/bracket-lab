require "test_helper"

class InviteTest < ActiveSupport::TestCase
  test "requires email address" do
    invite = Invite.new(full_name: "Test User")
    assert_not invite.valid?
    assert_includes invite.errors[:email_address], "can't be blank"
  end

  test "email normalization" do
    invite = Invite.new(email_address: "TEST@EXAMPLE.COM ", full_name: "Test User", created_by: users(:admin_user))
    assert_equal "test@example.com", invite.email_address
  end

  test "email format validation" do
    invite = Invite.new(full_name: "Test User", created_by: users(:admin_user), email_address: "foo.com")
    assert_not invite.valid?
    assert_includes invite.errors[:email_address], "is invalid"
  end

  test "requires full name" do
      invite = Invite.new(email_address: "test@example.com")
      assert_not invite.valid?
      assert_includes invite.errors[:full_name], "can't be blank"
  end

  test "generates token on creation" do
    invite = Invite.create!(
      email_address: "test@example.com",
      full_name: "Test User",
      created_by: users(:admin_user)
    )
    assert_not_nil invite.token
  end

  test "sets expiration on creation" do
    invite = Invite.create!(
      email_address: "test@example.com",
      full_name: "Test User",
      created_by: users(:admin_user)
    )
    assert_equal 7.days.from_now.to_date, invite.expires_at.to_date
  end

  test "payment_credits cannot be negative" do
    invite = invites(:valid_invite)
    invite.payment_credits = -1
    assert_not invite.valid?
    assert_includes invite.errors[:payment_credits], "must be greater than or equal to 0"
  end

  test "valid_for_use? returns false when used" do
    invite = invites(:used_invite)
    assert invite.valid_for_use? == false
  end

  test "valid_for_use? returns false when expired" do
    invite = invites(:expired_invite)
    assert_not invite.valid_for_use?
  end
end
