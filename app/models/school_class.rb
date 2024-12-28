class SchoolClass < ApplicationRecord
  include AccountScoped

  validates :name, presence: true
  validates :ordinal, presence: true
end
