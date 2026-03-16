require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Configure Capybara for better stability
  Capybara.default_max_wait_time = 5
  Capybara.automatic_reload = true

  # System tests are not safe for parallel execution due to shared browser state,
  # JavaScript execution context, and potential race conditions in async operations
  parallelize(workers: 1)

  # Include system test helpers
  include ScheduleTestHelper

  def log_in_as(user)
    visit sign_in_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "Secret1*3*5*"
    click_on "Sign in"
    assert_text "Signed in successfully"
  end

  # Wait for Stimulus controller to finish loading data via AJAX
  # @param controller_name [String] The Stimulus controller name (e.g., 'reschedule')
  # @param timeout [Integer] Maximum seconds to wait (default: 5)
  def wait_for_ajax_load(controller_name, timeout: 5)
    assert_no_selector "[data-#{controller_name}-target='loadingIndicator']:not(.hidden)", wait: timeout
  end

  # Define a flaky test that will retry on failure
  # Use sparingly - prefer fixing root cause over retrying
  # This is a temporary safety net while addressing underlying issues
  # @param name [String] Test name
  # @param retries [Integer] Number of retry attempts (default: 2)
  def self.flaky_test(name, retries: 2, &block)
    test(name) do
      attempts = 0
      begin
        instance_eval(&block)
      rescue => e
        attempts += 1
        if attempts <= retries
          puts "\n⚠️  Test '#{name}' failed, retrying (#{attempts}/#{retries})..."
          puts "   Error: #{e.message}"
          retry
        else
          puts "\n❌ Test '#{name}' failed after #{retries} retries"
          raise e
        end
      end
    end
  end
end
