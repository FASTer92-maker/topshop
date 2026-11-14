class Subscriber < ApplicationRecord
  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: true

  # Subscribing twice is not an error: the existing record is returned, so the
  # response cannot be used to check whether an address is already stored.
  def self.subscribe(email)
    find_or_create_by(email: email)
  end
end
