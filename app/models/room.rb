class Room < ApplicationRecord
  include AccountScoped

  belongs_to :schedule
  has_many :performance_steps, dependent: :delete_all

  validates :name, :room_number, presence: true
  validates :room_number, uniqueness: { scope: :schedule_id }
end
