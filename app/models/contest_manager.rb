class ContestManager < ApplicationRecord
  include AccountScoped

  belongs_to :contest
  belongs_to :user

  validates :contest_id, uniqueness: { scope: [ :user_id ] }
end
