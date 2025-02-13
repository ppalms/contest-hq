class Room < ApplicationRecord
  include AccountScoped

  belongs_to :contest

  validates :name, :room_number, presence: true
  validates :room_number, uniqueness: { scope: :contest_id }
end
