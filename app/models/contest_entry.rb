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

  scope :for_ensemble_in_season, ->(large_ensemble_id, season_id) {
    joins(:contest)
    .where(large_ensemble_id: large_ensemble_id, contests: { season_id: season_id })
    .order(created_at: :desc)
  }

  validate :preferred_time_within_contest_hours, if: :has_time_preference?
  validate :school_class_eligible_for_contest

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

  def music_complete?
    return false unless contest

    prescribed_count = music_selections.count(&:prescribed?)
    custom_count = music_selections.count(&:custom?)

    prescribed_count == contest.required_prescribed_count &&
      custom_count == contest.required_custom_count
  end

  def prescribed_selection
    music_selections.find { |ms| ms.prescribed? }
  end

  def custom_selections
    music_selections.select { |ms| ms.custom? }
  end

  def required_music_slots
    return [] unless contest

    existing_selections = music_selections.order(:position).to_a
    prescribed_count = existing_selections.count(&:prescribed?)
    custom_count = existing_selections.count(&:custom?)

    slots = []
    (1..contest.total_required_music_count).each do |position|
      music_selection = existing_selections.find { |ms| ms.position == position }

      if music_selection
        slot_type = music_selection.prescribed? ? :prescribed : :custom
      else
        if prescribed_count < contest.required_prescribed_count
          slot_type = :prescribed
          prescribed_count += 1
        else
          slot_type = :custom
          custom_count += 1
        end
      end

      slots << {
        position: position,
        type: slot_type,
        music_selection: music_selection
      }
    end

    slots
  end

  def missing_prescribed_count
    return 0 unless contest

    required = contest.required_prescribed_count
    current = music_selections.count(&:prescribed?)
    [ required - current, 0 ].max
  end

  def missing_custom_count
    return 0 unless contest

    required = contest.required_custom_count
    current = music_selections.count(&:custom?)
    [ required - current, 0 ].max
  end

  def previous_entry_in_season
    return nil unless contest&.season_id && large_ensemble_id

    self.class
      .for_ensemble_in_season(large_ensemble_id, contest.season_id)
      .where.not(id: id)
      .first
  end

  private

  def school_class_eligible_for_contest
    return unless large_ensemble && contest

    # If contest has no school class restrictions, all schools are eligible
    return if contest.school_classes.empty?

    school_class = large_ensemble.school.school_class
    unless contest.school_classes.include?(school_class)
      errors.add(:large_ensemble, "is from a #{school_class.name} school, but this contest is restricted to #{contest.school_classes.pluck(:name).join(', ')} schools")
    end
  end

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
