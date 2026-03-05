require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "requires full name" do
    user = User.new(email_address: "test@example.com", password: "password")
    assert_not user.valid?
    assert_includes user.errors[:full_name], "can't be blank"
  end

  test "email normalization" do
    user = User.new(email_address: "AbC@Ex-amp.COM ", full_name: "Test User")
    assert_equal("abc@ex-amp.com", user.email_address)
  end

  test "admin defaults to false" do
    user = User.new(
      email_address: "test@example.com",
      full_name: "Test User",
      password: "password"
    )
    assert_not user.admin?
  end

  test "can create admin user" do
    admin = users(:admin_user)
    assert admin.admin?
  end
end
