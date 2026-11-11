class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :variant

  delegate :product, to: :variant

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :variant_id, uniqueness: { scope: :cart_id }
  validate :variant_must_be_available

  def subtotal
    quantity * product.price
  end

  private
    def variant_must_be_available
      return if variant.nil? || !quantity.is_a?(Integer) || quantity <= 0
      return if variant.available?(quantity)

      if variant.product.active?
        errors.add(:quantity, :insufficient_stock, available: variant.stock)
      else
        errors.add(:quantity, :product_unavailable)
      end
    end
end
