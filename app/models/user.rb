class User < ApplicationRecord
  has_secure_password

  generates_token_for :email_verification, expires_in: 2.days do
    email
  end

  generates_token_for :password_reset, expires_in: 20.minutes do
    password_salt.last(10)
  end

  has_many :user_roles
  has_many :roles, through: :user_roles

  belongs_to :account

  has_many :sessions, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: 12 }

  normalizes :email, with: -> { _1.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  before_validation on: :create do
    self.account ||= Account.find_or_create_by!(name: "Contest HQ")
  end

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
  end

  def sysadmin?
    roles.exists?(name: "SysAdmin")
  end

  def tenant_admin?
    roles.exists?(name: "TenantAdmin")
  end

  def director?
    roles.exists?(name: "Director")
  end

  def scheduler?
    roles.exists?(name: "Scheduler")
  end

  def judge?
    roles.exists?(name: "Judge")
  end
end
