class ScheduleBlock < ApplicationRecord
  include AccountScoped

  belongs_to :day
  belongs_to :room, optional: true

  validates :start_time, :end_time, presence: true
  validate :end_time_after_start_time
  validate :no_overlap

  private

  def end_time_after_start_time
    return unless start_time && end_time

    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end

  def no_overlap
    return unless day

    if day.schedule_blocks.any? do |block|
      block != self &&
        block.room == room &&
        block.start_time < end_time &&
        block.end_time > start_time
      end

      errors.add(:start_time, "overlaps with another block")
    end
  end
end
