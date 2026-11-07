class User < ApplicationRecord
  PASSWORD_MIN_LENGTH = 8

  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(email) { email.strip.downcase }
  normalizes :first_name, :last_name, with: ->(name) { name.squish }

  validates :email_address, presence: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP },
                            uniqueness: true
  validates :first_name, :last_name, presence: true, length: { maximum: 50 }
  validates :password, length: { minimum: PASSWORD_MIN_LENGTH }, allow_nil: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
