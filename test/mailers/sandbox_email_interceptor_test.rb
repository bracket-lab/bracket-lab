require "test_helper"

class SandboxEmailInterceptorTest < ActiveSupport::TestCase
  setup do
    @original_sandbox_email = ENV["SANDBOX_EMAIL_ADDRESS"]
    ENV["SANDBOX_EMAIL_ADDRESS"] = "sandbox@example.com"
    @message = Mail::Message.new(to: [ "user@example.com" ])
  end

  teardown do
    ENV["SANDBOX_EMAIL_ADDRESS"] = @original_sandbox_email
  end

  test "redirects email to sandbox address when configured" do
    SandboxEmailInterceptor.delivering_email(@message)
    assert_equal [ "sandbox@example.com" ], @message.to
  end

  test "does not modify email when sandbox address is not configured" do
    ENV["SANDBOX_EMAIL_ADDRESS"] = nil
    original_to = @message.to.dup

    SandboxEmailInterceptor.delivering_email(@message)
    assert_equal original_to, @message.to
  end
end
