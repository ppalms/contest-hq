class Schedule < ApplicationRecord
  include AccountScoped

  belongs_to :contest

  has_many :schedule_days, dependent: :destroy

  validates :contest_id, uniqueness: true

  def days
    schedule_days.order(:start_time)
  end

  def initialize_days(start_time, end_time)
    contest.contest_start.to_date.upto(contest.contest_end.to_date) do |date|
      contest_start_time = date.to_datetime.change(
        hour: start_time.hour,
        min: start_time.min
      )

      contest_end_time = date.to_datetime.change(
        hour: end_time.hour,
        min: end_time.min
      )

      day = days.build(
        schedule_date: date,
        start_time: contest_start_time,
        end_time: contest_end_time
      )

      unless day.save
        Rails.logger.error "Failed to save schedule day: #{day.errors.full_messages.join(', ')}"
      end
    end
  end
end
