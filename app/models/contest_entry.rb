class ContestEntry < ApplicationRecord
  belongs_to :contest
  belongs_to :user
  belongs_to :large_group
end
