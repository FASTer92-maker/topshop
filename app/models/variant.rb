class Variant < ApplicationRecord
  SIZES = [ "XS", "S", "M", "L", "XL", "XXL", "ONE SIZE" ].freeze
  LOW_STOCK_LIMIT = 3

  belongs_to :product, inverse_of: :variants
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :restrict_with_error

  normalizes :sku, with: ->(sku) { sku.strip.upcase }
  normalizes :color, with: ->(color) { color.strip.capitalize }

  validates :size, presence: true, inclusion: { in: SIZES }
  validates :color, presence: true, length: { maximum: 50 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :sku, presence: true, uniqueness: true
  validates :size, uniqueness: { scope: %i[product_id color] }

  scope :in_stock, -> { where("variants.stock > 0") }
  scope :low_stock, ->(limit = LOW_STOCK_LIMIT) { where(stock: ..limit) }
  scope :by_size, -> { in_order_of(:size, SIZES) }

  def available?(quantity = 1)
    product.active? && stock >= quantity
  end

  def label
    "#{size} · #{color}"
  end

  def low_stock?
    stock < LOW_STOCK_LIMIT
  end
end
