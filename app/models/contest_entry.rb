class ContestEntry < ApplicationRecord
  include AccountScoped

  belongs_to :contest
  belongs_to :user
  belongs_to :large_ensemble

  has_many :music_selections, dependent: :destroy
  has_many :schedule_blocks

  scope :in_order, -> {
    joins(large_ensemble: :performance_class)
    .order("performance_classes.ordinal DESC")
  }
end
