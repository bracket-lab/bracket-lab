ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all

    include Rails.application.routes.url_helpers
    Rails.application.routes.default_url_options[:host] = "example.com"
  end
end

module SignInHelper
  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
