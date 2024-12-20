class SchoolDirector < ApplicationRecord
  include AccountScoped

  belongs_to :user
  belongs_to :school
end
