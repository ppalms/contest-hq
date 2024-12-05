module AccountScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :account

    # Ignore account scope for a block of code
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

      # Apply account scope if we have an account
      Current.account ? where(account: Current.account) : none
    }
  end
end
