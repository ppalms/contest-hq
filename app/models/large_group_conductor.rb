class LargeGroupConductor < ApplicationRecord
  include AccountScoped

  belongs_to :user
  belongs_to :large_group

  validates :large_group_id, uniqueness: { scope: [ :user_id ] }
  validate :ensure_matching_accounts

  private

  def ensure_matching_accounts
    if large_group.account_id != user.account_id
      errors.add(:base, "Group and user must belong to the same account")
    end
  end
end
