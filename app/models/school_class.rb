class SchoolClass < ApplicationRecord
  include AccountScoped

  has_many :prescribed_musics, dependent: :restrict_with_error

  validates :name, presence: true
  validates :ordinal, presence: true
end
