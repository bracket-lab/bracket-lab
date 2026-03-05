require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset" do
    user = users(:john)
    email = PasswordsMailer.reset(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "from@example.com" ], email.from
    assert_equal [ user.email_address ], email.to
    assert_equal "Reset your password", email.subject

    # Test both HTML and text parts
    assert_includes email.html_part.body.to_s, "Reset your password"
    assert_includes email.html_part.body.to_s, "this password reset page"
    assert_includes email.text_part.body.to_s, "Reset your password"
    assert_includes email.text_part.body.to_s, "following URL"
  end
end
