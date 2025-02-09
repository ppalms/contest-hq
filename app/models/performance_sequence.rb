class PerformanceSequence < ApplicationRecord
  include AccountScoped
  belongs_to :schedule
  has_many :performance_steps, dependent: :destroy, inverse_of: :performance_sequence
  accepts_nested_attributes_for :performance_steps,
                              allow_destroy: true,
                              reject_if: :all_blank
  validates :schedule_id, uniqueness: true
end
