class LargeEnsembleConductor < ApplicationRecord
  include AccountScoped

  belongs_to :user
  belongs_to :large_ensemble

  validates :large_ensemble_id, uniqueness: { scope: [ :user_id ] }
  validate :ensure_matching_accounts

  private

  def ensure_matching_accounts
    if large_ensemble.account_id != user.account_id
      errors.add(:base, "Large ensemble and director must belong to the same account")
    end
  end
end
