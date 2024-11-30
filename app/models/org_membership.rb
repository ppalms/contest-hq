class OrgMembership < ApplicationRecord
  include AccountScoped

  belongs_to :user
  belongs_to :organization
end
