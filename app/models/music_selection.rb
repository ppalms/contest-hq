class MusicSelection < ApplicationRecord
  include AccountScoped

  belongs_to :contest_entry

  validates :title, presence: true
  validates :composer, presence: true
end
