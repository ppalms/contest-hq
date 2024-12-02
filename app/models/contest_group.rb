class ContestGroup < ApplicationRecord
  include AccountScoped

  validates :name, presence: true

  belongs_to :organization
  belongs_to :contest_group_class

  has_many :contest_group_conductors
  has_many :conductors, through: :contest_group_conductors, source: :user
end
