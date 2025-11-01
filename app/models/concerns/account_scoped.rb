module AccountScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :account

    before_validation on: :create do
      self.account ||= Current.account
    end

    # Ignore account scope for a block of code and then reapply
    def self.unscoped_by_account
      old_scope = default_scopes
      self.default_scopes = []

      yield
    ensure
      self.default_scopes = old_scope
    end

    default_scope -> {
      # Don't apply account scope during authentication
      return all unless Current.user.present?

      # Don't apply account scope if we're explicitly told not to
      return all if Thread.current[:skip_account_scope]

      # For sys_admins, show cross account data only if no account is selected
      if Current.user.sys_admin?
        return all if Current.selected_account.nil?
        return where(account: Current.selected_account)
      end

      # Apply account scope if we have an account
      Current.account ? where(account: Current.account) : none
    }
  end
end
