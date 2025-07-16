require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Only add Chrome arguments if running in a containerized environment (like Codespaces)
  if ENV['CODESPACES'] || ENV['CONTAINER']
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
    end
  else
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  end

  def log_in_as(user)
    visit sign_in_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "Secret1*3*5*"
    find('input[type="submit"][value="Sign in"]').click
    assert_text "Signed in successfully"
  end
end
