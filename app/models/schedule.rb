class Schedule < ApplicationRecord
  include AccountScoped

  belongs_to :contest
  has_one :performance_phase, dependent: :destroy
  has_many :days, dependent: :destroy
  has_many :rooms, dependent: :destroy

  validates :contest_id, uniqueness: true

  after_create :initialize_performance_phase

  def initialize_days(start_time, end_time)
    for date in contest.start_date..contest.end_date
      days.create(date: date, start_time: start_time, end_time: end_time)
    end
  end

  class Day < ApplicationRecord
    belongs_to :schedule

    validates :date, :start_time, :end_time, presence: true
    validates :date, uniqueness: { scope: :schedule_id }
    validate :end_time_after_start_time

    def end_time_after_start_time
      return unless start_time && end_time

      if end_time <= start_time
        errors.add(:end_time, "must be after start time")
      end
    end
  end

  private

  def initialize_performance_phase
    self.performance_phase ||= PerformancePhase.new
  end
end
