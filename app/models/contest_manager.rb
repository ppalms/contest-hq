class ContestManager < ApplicationRecord
  include AccountScoped

  belongs_to :contest
  belongs_to :user

  validates :contest_id, uniqueness: { scope: [ :user_id ] }
  validate :user_must_be_manager

  private

  def user_must_be_manager
    return if user.nil?

    unless user.manager?
      errors.add(:user, "must have the Manager role")
    end
  end
end
