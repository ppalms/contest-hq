class PerformancePhase < ApplicationRecord
  include AccountScoped

  belongs_to :contest, inverse_of: :performance_phases
  belongs_to :room

  validates :ordinal, :name, :duration, presence: true
  validates :duration, numericality: { greater_than: 0 }
  validates :room, presence: true

  scope :in_order, -> { order(ordinal: :asc) }
  scope :by_ordinal, -> { order(ordinal: :asc) }
end
