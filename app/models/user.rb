class User < ApplicationRecord
  PASSWORD_MIN_LENGTH = 8

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :cart, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_products, through: :favorites, source: :product
  has_many :orders, dependent: :restrict_with_error

  enum :role, { customer: 0, admin: 1 }, default: :customer

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

  def cart!
    cart || create_cart!
  end

  def favorite?(product)
    favorites.exists?(product_id: product.id)
  end

  # Returns true when the product is in favourites after the call.
  def toggle_favorite!(product)
    favorite = favorites.find_by(product: product)

    if favorite
      favorite.destroy!
      false
    else
      favorites.create!(product: product)
      true
    end
  end
end
