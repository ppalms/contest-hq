class Room < ApplicationRecord
  include AccountScoped

  belongs_to :contest
  has_many :performance_steps, dependent: :delete_all

  validates :name, :room_number, presence: true
  validates :room_number, uniqueness: { scope: :contest_id }
end
