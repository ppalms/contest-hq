class LargeGroupClass < ApplicationRecord
  include AccountScoped

  validates :name, presence: true
end
