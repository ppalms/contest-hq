class LargeEnsembleConductor < ApplicationRecord
  include AccountScoped

  belongs_to :user
  belongs_to :large_ensemble

  validates :large_ensemble_id, uniqueness: { scope: [ :user_id ] }
end
