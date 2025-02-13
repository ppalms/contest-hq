class Contest < ApplicationRecord
  include AccountScoped

  has_many :contests_school_classes, dependent: :delete_all
  has_many :school_classes, through: :contests_school_classes

  has_many :contest_managers, dependent: :delete_all
  has_many :managers, through: :contest_managers, source: :user

  has_many :rooms
  has_many :performance_phases, dependent: :delete_all, inverse_of: :contest
  accepts_nested_attributes_for :performance_phases, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true
  validate :start_date_before_end_date
  validate :unique_contest_phases

  private

  def start_date_before_end_date
    if contest_start.present? && contest_end.present? && contest_end < contest_start
      errors.add(:contest_end, "date must be after start date")
    end
  end

  def unique_contest_phases
    performance_phases&.each do |phase|
      next if phase.marked_for_destruction?
      next unless phase.ordinal_changed?

      conflicting_phase = performance_phases
        .reject { |p| p.marked_for_destruction? || p.id == phase.id }
        .find { |p| p.ordinal == phase.ordinal }

      if conflicting_phase
        errors.add(:base, "Phase #{phase.ordinal} specified more than once")
      end
    end
  end
end
