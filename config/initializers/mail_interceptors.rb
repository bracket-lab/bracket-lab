# https://guides.rubyonrails.org/action_mailer_basics.html#intercepting-emails

class SandboxEmailInterceptor
  def self.delivering_email(message)
    if ENV["SANDBOX_EMAIL_ADDRESS"].present?
      message.to = [ ENV["SANDBOX_EMAIL_ADDRESS"] ]
    end
  end
end

Rails.application.configure do
  if ENV["SANDBOX_EMAIL_ADDRESS"].present?
    config.action_mailer.interceptors = %w[SandboxEmailInterceptor]
  end
end
