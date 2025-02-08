class RoomBlock < ApplicationRecord
  include AccountScoped

  belongs_to :room

  validates :duration, presence: true
  validates :duration, numericality: { greater_than: 0 }
end
