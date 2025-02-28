class PerformanceClass < ApplicationRecord
  include AccountScoped

  scope :in_order, -> { order(:ordinal) }

  validates :name, presence: true
  validates :ordinal, presence: true
end
