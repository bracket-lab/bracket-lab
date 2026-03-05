require "test_helper"

class InvitesMailerTest < ActionMailer::TestCase
  test "invite" do
    invite = invites(:valid_invite)
    email = InvitesMailer.invite(invite)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "from@example.com" ], email.from
    assert_equal [ invite.email_address ], email.to
    assert_equal "You've been invited to join #{Rails.configuration.env[:pool_name]}!", email.subject

    # Test both HTML and text parts
    assert_includes email.html_part.body.to_s, invite.full_name
    assert_includes email.html_part.body.to_s, new_invite_acceptance_path(token: invite.token)
    assert_includes email.text_part.body.to_s, invite.full_name
    assert_includes email.text_part.body.to_s, new_invite_acceptance_path(token: invite.token)
  end
end
