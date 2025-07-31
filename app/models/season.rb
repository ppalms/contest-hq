class Season < ApplicationRecord
  include AccountScoped

  has_many :contests, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :archived, inclusion: { in: [true, false] }

  scope :current, -> { where(archived: false).order(created_at: :desc) }
  scope :by_name, -> { order(:name) }

  def self.current_season
    current.first
  end

  def display_name
    archived? ? "#{name} (Archived)" : name
  end
end