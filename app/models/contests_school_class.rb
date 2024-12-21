class ContestsSchoolClass < ApplicationRecord
  include AccountScoped

  belongs_to :contest
  belongs_to :school_class
end
