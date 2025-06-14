class User < ApplicationRecord
  include AccountScoped

  has_secure_password

  generates_token_for :email_verification, expires_in: 2.days do
    email
  end

  generates_token_for :password_reset, expires_in: 20.minutes do
    password_salt.last(10)
  end

  has_many :school_directors, dependent: :delete_all
  has_many :schools, through: :school_directors

  has_many :large_ensemble_conductors, dependent: :delete_all
  has_many :conducted_ensembles, through: :large_ensemble_conductors, source: :large_ensemble

  has_many :contest_managers, dependent: :delete_all
  has_many :managed_contests, through: :contest_managers, source: :contest

  has_many :contest_entries

  has_many :user_roles, dependent: :delete_all
  has_many :roles, through: :user_roles
  has_many :sessions, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: 12 }
  validates :time_zone, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map { |tz| tz.tzinfo.name } }

  normalizes :email, with: -> { _1.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  before_validation on: :create do
    self.account ||= Current.account
  end

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
  end

  def role_names
    @role_names ||= roles.pluck(:name)
  end

  def sysadmin?
    role_names.include?("SysAdmin")
  end

  def tenant_admin?
    role_names.include?("AccountAdmin")
  end

  def director?
    role_names.include?("Director")
  end

  def manager?
    role_names.include?("Manager")
  end

  def judge?
    role_names.include?("Judge")
  end

  def admin?
    sysadmin? || tenant_admin?
  end

  def manages_contest(contest_id)
    if !manager?
      return false
    end

    managed_contests&.exists?(contest_id)
  end
end
