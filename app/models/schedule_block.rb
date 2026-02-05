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
      Rails.logger.error "Overlap detected for block: room=#{room.name}, start=#{start_time}, end=#{end_time}, entry=#{contest_entry&.large_ensemble&.name}, phase=#{performance_phase&.name}"
      overlapping_blocks.each do |existing|
        Rails.logger.error "  Conflicts with: room=#{existing.room.name}, start=#{existing.start_time}, end=#{existing.end_time}, entry=#{existing.contest_entry&.large_ensemble&.name}, phase=#{existing.performance_phase&.name}"
        Rails.logger.error "  Overlap check: #{existing.start_time} < #{end_time} = #{existing.start_time < end_time}, #{existing.end_time} > #{start_time} = #{existing.end_time > start_time}"
      end
      errors.add(:start_time, "overlaps with another block in this room")
    end
  end
end
