class Contest < ApplicationRecord
  include AccountScoped

  validates :name, presence: true

  validate :start_date_before_end_date

  private

  def start_date_before_end_date
    if contest_start.present? && contest_end.present? && contest_end < contest_start
      errors.add(:contest_end, "date must be after start date")
    end
  end
end
