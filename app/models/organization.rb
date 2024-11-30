class Organization < ApplicationRecord
  include AccountScoped

  belongs_to :organization_type

  has_many :org_memberships, dependent: :delete_all
  has_many :users, through: :org_memberships

  validates :name, presence: true
end
