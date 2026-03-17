class Season < ApplicationRecord
  include AccountScoped

  has_many :contests, dependent: :restrict_with_error
  has_many :prescribed_musics, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :archived, inclusion: { in: [ true, false ] }
  validates :ordinal, presence: true, uniqueness: { scope: :account_id }

  scope :current, -> { where(archived: false).order(ordinal: :desc) }
  scope :by_ordinal, -> { order(ordinal: :desc) }
  scope :by_name, -> { order(:name) }

  before_validation :assign_ordinal, on: :create, if: -> { ordinal.blank? }

  def self.current_season
    current.first
  end

  def display_name
    archived? ? "#{name} (Archived)" : name
  end

  private

  def assign_ordinal
    max_ordinal = Season.where(account_id: account_id).maximum(:ordinal) || 0
    self.ordinal = max_ordinal + 1
  end
end
