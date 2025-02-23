class ScheduleDay < ApplicationRecord
  include AccountScoped

  belongs_to :schedule
  has_many :schedule_blocks, dependent: :destroy

  validates :schedule_date, :start_time, :end_time, presence: true
  validates :schedule_date, uniqueness: { scope: :schedule_id }
  validate :end_time_after_start_time

  def end_time_after_start_time
    return unless start_time && end_time

    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end
end
