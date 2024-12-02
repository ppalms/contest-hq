class ContestGroupClass < ApplicationRecord
  include AccountScoped

  validates :name, presence: true
end
