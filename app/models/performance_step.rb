class PerformanceStep < ApplicationRecord
  include AccountScoped

  belongs_to :performance_sequence, inverse_of: :performance_steps
  belongs_to :room

  validates :duration, presence: true
  validates :duration, numericality: { greater_than: 0 }
  validates :ordinal, :name, presence: true
  validate :unique_ordinal_within_sequence

  scope :in_order, -> { order(ordinal: :asc) }

  private

  def unique_ordinal_within_sequence
    return if marked_for_destruction?
    return unless ordinal_changed?

    conflicting_step = performance_sequence.performance_steps
      .reject { |step| step.marked_for_destruction? || step.id == id }
      .find { |step| step.ordinal == ordinal }

    if conflicting_step
      errors.add(:ordinal, "Step #{ordinal} specified more than once")
    end
  end
end
