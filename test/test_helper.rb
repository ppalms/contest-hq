ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "ostruct"

Dir[Rails.root.join("test/support/**/*.rb")].each { |f| require f }

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...

  # For integration tests - signs in a user via HTTP request
  def sign_in_as(user)
    post(sign_in_url, params: { email: user.email, password: "Secret1*3*5*" }); user
  end

  # For model tests - sets Current directly
  def set_current_user(user)
    Current.session = OpenStruct.new(user: user)
    Current.account = user.account
  end

  # Ensure Current is cleaned up after each test
  teardown do
    Current.reset
  end
end
