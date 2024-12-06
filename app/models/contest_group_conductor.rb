class ContestGroupConductor < ApplicationRecord
  include AccountScoped

  belongs_to :user
  belongs_to :contest_group

  validates :contest_group_id, uniqueness: { scope: [ :user_id ] }
  validate :ensure_matching_accounts

  private

  def ensure_matching_accounts
    if contest_group.account_id != user.account_id
      errors.add(:base, "Contest group and user must belong to the same account")
    end
  end
end
