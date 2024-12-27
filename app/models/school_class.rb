class SchoolClass < ApplicationRecord
  include AccountScoped

  belongs_to :school

  validates :name, presence: true
  validates :ordinal, presence: true
end
