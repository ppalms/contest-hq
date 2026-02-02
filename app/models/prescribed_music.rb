class PrescribedMusic < ApplicationRecord
  include AccountScoped

  belongs_to :season
  belongs_to :school_class
  has_many :music_selections, dependent: :destroy

  validates :title, presence: true
  validates :composer, presence: true
  validates :season, presence: true
  validates :school_class, presence: true

  scope :for_season, ->(season_id) { where(season_id: season_id) }
  scope :for_school_class, ->(school_class_id) { where(school_class_id: school_class_id) }
  scope :by_title, -> { order(:title) }

  def display_name
    "#{title} - #{composer}"
  end
end
