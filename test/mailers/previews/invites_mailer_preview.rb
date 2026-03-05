class InvitesMailerPreview < ActionMailer::Preview
  def invite
    invite = Invite.pending.first ||
      Invite.create!(
        email_address: "preview@example.com",
        full_name: "Preview User",
        created_by: User.first,
        token: "preview_token",
        expires_at: 7.days.from_now
      )

    InvitesMailer.invite(invite)
  end
end
