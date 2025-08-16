class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :user_agent, :ip_address

  attribute :account
  attribute :selected_account

  delegate :user, to: :session, allow_nil: true

  def session=(session)
    super; self.account = session.user.account
  end

  # Returns the selected account for sysadmins, or the user's account for regular users
  def effective_account
    selected_account || account
  end
end
