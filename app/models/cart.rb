class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, dependent: :destroy
  has_many :variants, through: :cart_items

  validates :user_id, uniqueness: true

  # Adds the variant to the cart and increases the quantity of an existing row.
  # Returns the item: a rejected quantity leaves it unpersisted with errors.
  def add_variant(variant, quantity = 1)
    item = cart_items.find_or_initialize_by(variant: variant)
    item.quantity = item.persisted? ? item.quantity + quantity : quantity
    item.save

    item
  end

  def subtotal
    cart_items.joins(variant: :product).sum("cart_items.quantity * products.price")
  end

  def delivery_price
    Delivery.price_for(subtotal)
  end

  def total
    subtotal + delivery_price
  end

  def amount_to_free_delivery
    Delivery.amount_to_free(subtotal)
  end

  def items_count
    cart_items.sum(:quantity)
  end

  def empty?
    cart_items.none?
  end

  def checkout_ready?
    !empty? && unavailable_items.empty?
  end

  # Rows whose product was hidden or whose stock dropped below the quantity.
  def unavailable_items
    cart_items.includes(variant: :product).reject(&:available?)
  end
end
