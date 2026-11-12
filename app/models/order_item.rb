class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :variant

  delegate :product, to: :variant

  # product_name, size, color and unit_price are snapshots taken when the order
  # is placed, so later catalog edits do not rewrite the history.
  validates :product_name, :size, :color, presence: true
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }

  def subtotal
    unit_price * quantity
  end
end
