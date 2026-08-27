module AccountScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :account

    before_validation on: :create do
      self.account ||= Current.effective_account
    end

    default_scope -> {
      # Fail closed: without an account context, expose nothing
      return none unless Current.account.present?

      # For sys_admins, show cross account data only if no account is selected
      if Current.user&.sys_admin?
        return all if Current.selected_account.nil?
        return where(account: Current.selected_account)
      end

      where(account: Current.account)
    }

    validate :associated_records_belong_to_same_account
  end

  private

  def associated_records_belong_to_same_account
    self.class.reflect_on_all_associations(:belongs_to).each do |reflection|
      next if reflection.name == :account
      next unless reflection.klass.include?(AccountScoped)

      foreign_key = reflection.foreign_key
      next unless public_send(foreign_key).present?

      associated = public_send(reflection.name)
      if associated.nil? || associated.account_id != account_id
        errors.add(reflection.name, "must belong to the same account")
      end
    end
  end
end
