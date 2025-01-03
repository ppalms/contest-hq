class ContestEntry < ApplicationRecord
  include AccountScoped

  belongs_to :contest
  belongs_to :user
  belongs_to :large_ensemble

  has_many :music_selections
end
