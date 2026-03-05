class InvitesMailer < ApplicationMailer
  def invite(invite)
    @invite = invite
    @url = new_invite_acceptance_url(token: @invite.token)
    @pool_name = Rails.configuration.env[:pool_name]

    mail to: @invite.email_address,
         subject: "You've been invited to join #{@pool_name}!"
  end
end
