class ContestSeason < ApplicationRecord
  include AccountScoped

  has_many :contests, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :account_id }
end
