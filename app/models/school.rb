class School < ApplicationRecord
  include AccountScoped

  belongs_to :school_class

  validates :name, presence: true
  validates :school_class, presence: true
end
