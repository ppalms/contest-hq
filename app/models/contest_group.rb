class ContestGroup < ApplicationRecord
  include AccountScoped

  validates :name, presence: true

  belongs_to :organization
  belongs_to :contest_group_class

  has_many :contest_group_conductors, dependent: :delete_all
  has_many :conductors, through: :contest_group_conductors, source: :user

  after_create :add_current_user_conductor

  private

  def add_current_user_conductor
    self.conductors << Current.user
  end
end
