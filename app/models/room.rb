class Room < ApplicationRecord
  include AccountScoped

  belongs_to :contest
  has_many :performance_phases, dependent: :destroy

  validates :name, :room_number, presence: true
  validates :room_number, uniqueness: { scope: :contest_id }
end
