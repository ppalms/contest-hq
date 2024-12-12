class LargeGroup < ApplicationRecord
  include AccountScoped
  # TODO: user scoped concern

  validates :name, presence: true

  belongs_to :organization
  belongs_to :large_group_class

  has_many :large_group_conductors, dependent: :delete_all
  has_many :conductors, through: :large_group_conductors, source: :user

  after_create :add_current_user_conductor

  private

  def add_current_user_conductor
    self.conductors << Current.user
  end
end
