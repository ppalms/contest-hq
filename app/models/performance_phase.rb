class PerformancePhase < ApplicationRecord
  include AccountScoped

  belongs_to :contest, inverse_of: :performance_phases
  belongs_to :room

  validates :ordinal, :name, :duration, presence: true
  validates :duration, numericality: { greater_than: 0 }

  scope :in_order, -> { order(ordinal: :asc) }
end
