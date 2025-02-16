class Schedule < ApplicationRecord
  include AccountScoped

  belongs_to :contest
  has_many :days, dependent: :destroy

  validates :contest_id, uniqueness: true

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
end
