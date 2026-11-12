# Delivery tariffs. Stage 14 reuses them to snapshot the price in an order.
module Delivery
  FREE_FROM = 10_000
  PRICE = 400

  module_function

  def price_for(subtotal)
    subtotal >= FREE_FROM ? 0 : PRICE
  end

  def amount_to_free(subtotal)
    [ FREE_FROM - subtotal, 0 ].max
  end
end
