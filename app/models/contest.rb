class Contest < ApplicationRecord
  include AccountScoped

  has_many :contests_school_classes, dependent: :delete_all
  has_many :school_classes, through: :contests_school_classes

  has_many :contest_managers, dependent: :delete_all
  has_many :managers, through: :contest_managers, source: :user

  validates :name, presence: true
  validate :start_date_before_end_date

  private

  def start_date_before_end_date
    if contest_start.present? && contest_end.present? && contest_end < contest_start
      errors.add(:contest_end, "date must be after start date")
    end
  end
end
