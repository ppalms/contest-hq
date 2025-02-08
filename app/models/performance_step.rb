class PerformanceStep < ApplicationRecord
  include AccountScoped

  belongs_to :performance_sequence, inverse_of: :performance_steps
  belongs_to :room_block
  has_one :room, through: :room_block

  accepts_nested_attributes_for :room_block, allow_destroy: true
  validates :ordinal, :name, presence: true
  validate :unique_ordinal_within_sequence

  after_initialize :build_default_room_block

  scope :in_order, -> { order(ordinal: :asc) }

  private

  def build_default_room_block
    build_room_block if room_block.nil?
  end

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
