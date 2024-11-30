class OrganizationType < ApplicationRecord
  include AccountScoped

  has_many :organizations

  validates :name, presence: true
end
