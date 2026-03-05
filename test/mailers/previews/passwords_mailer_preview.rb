class PasswordsMailerPreview < ActionMailer::Preview
  def reset
    user = User.first
    PasswordsMailer.reset(user)
  end
end
