class ContestEntry < ApplicationRecord
  include AccountScoped

  belongs_to :contest
  belongs_to :user
  belongs_to :large_ensemble

  has_many :music_selections, dependent: :destroy
  has_many :schedule_blocks

  scope :performance_order, -> {
    joins(large_ensemble: :performance_class)
    .order("performance_classes.ordinal DESC")
  }

  validate :preferred_time_within_contest_hours, if: :has_time_preference?

  def has_time_preference?
    preferred_time_start.present? || preferred_time_end.present?
  end

  def full_time_preference?
    preferred_time_start.present? && preferred_time_end.present?
  end

  def within_preferred_time?(schedule_time)
    return true unless has_time_preference?

    time_only = schedule_time.strftime("%H:%M:%S")

    if full_time_preference?
      start_str = preferred_time_start.strftime("%H:%M:%S")
      end_str = preferred_time_end.strftime("%H:%M:%S")
      time_only >= start_str && time_only <= end_str
    elsif preferred_time_start.present?
      start_str = preferred_time_start.strftime("%H:%M:%S")
      time_only >= start_str
    elsif preferred_time_end.present?
      end_str = preferred_time_end.strftime("%H:%M:%S")
      time_only <= end_str
    else
      true
    end
  end

  private

  def preferred_time_within_contest_hours
    return unless has_time_preference? && contest&.start_time && contest&.end_time

    contest_start = contest.start_time.strftime("%H:%M:%S")
    contest_end = contest.end_time.strftime("%H:%M:%S")

    if preferred_time_start.present?
      start_str = preferred_time_start.strftime("%H:%M:%S")
      if start_str < contest_start || start_str > contest_end
        errors.add(:preferred_time_start, "must be within contest hours (#{contest.start_time.strftime('%l:%M %p')} - #{contest.end_time.strftime('%l:%M %p')})")
      end
    end

    if preferred_time_end.present?
      end_str = preferred_time_end.strftime("%H:%M:%S")
      if end_str < contest_start || end_str > contest_end
        errors.add(:preferred_time_end, "must be within contest hours (#{contest.start_time.strftime('%l:%M %p')} - #{contest.end_time.strftime('%l:%M %p')})")
      end
    end

    if full_time_preference?
      start_str = preferred_time_start.strftime("%H:%M:%S")
      end_str = preferred_time_end.strftime("%H:%M:%S")
      if start_str >= end_str
        errors.add(:preferred_time_end, "must be after preferred start time")
      end
    end
  end
end
