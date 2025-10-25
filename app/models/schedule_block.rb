class ScheduleBlock < ApplicationRecord
  include AccountScoped

  belongs_to :schedule_day
  belongs_to :room, optional: true
  belongs_to :performance_phase, optional: true
  belongs_to :contest_entry, optional: true

  validates :start_time, :end_time, presence: true
  validate :end_time_after_start_time
  validate :no_overlap

  scope :by_start_time, -> { order(:start_time) }

  private

  def end_time_after_start_time
    return unless start_time && end_time

    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end

  def no_overlap
    return unless schedule_day && start_time && end_time && room

    overlapping_blocks = ScheduleBlock
      .where(schedule_day_id: schedule_day_id)
      .where(room_id: room_id)
      .where("start_time < ? AND end_time > ?", end_time, start_time)

    overlapping_blocks = overlapping_blocks.where.not(id: id) if persisted?

    if overlapping_blocks.exists?
      errors.add(:start_time, "overlaps with another block in this room")
    end
  end
end
