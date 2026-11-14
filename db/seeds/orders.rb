# Demo orders for the customer account. They are placed through
# Order.place_from_cart!, so the stock is decremented honestly. Stable demo
# numbers make the seed idempotent: re-running it does not place the same
# order twice and does not touch the stock again.

customer = User.find_by!(email_address: "customer@example.com")

# Status paths from the default "pending" status to the target status.
demo_orders = [
  { number: "ORD-DEMO-0001", statuses: [], quantity: 1 },
  { number: "ORD-DEMO-0002", statuses: %i[ paid ], quantity: 2 },
  { number: "ORD-DEMO-0003", statuses: %i[ paid assembled ], quantity: 1 },
  { number: "ORD-DEMO-0004", statuses: %i[ paid assembled shipped ], quantity: 1 },
  { number: "ORD-DEMO-0005", statuses: %i[ paid assembled shipped delivered ], quantity: 2 }
]

customer_attributes = {
  full_name: "Покупатель Тестовый",
  phone: "+7 (999) 123-45-67",
  address: "Москва, ул. Тверская, 1",
  comment: "Демонстрационный заказ"
}

used_variant_ids = []
used_product_ids = []

demo_orders.each do |demo|
  order = customer.orders.find_by(number: demo.fetch(:number))

  unless order
    quantity = demo.fetch(:quantity)
    scope = Variant.joins(:product)
                   .where(products: { active: true })
                   .where("variants.stock >= ?", quantity)
                   .order(:product_id, :id)

    # Prefer a different product and a different variant for every demo order,
    # but fall back to any variant with enough stock if the catalogue runs short.
    variant = scope.where.not(product_id: used_product_ids).first ||
              scope.where.not(id: used_variant_ids).first ||
              scope.first!
    used_variant_ids << variant.id
    used_product_ids << variant.product_id

    cart = customer.cart!
    cart.add_variant(variant, quantity)
    order = Order.place_from_cart!(cart, customer_attributes.merge(number: demo.fetch(:number)))
  end

  # Advance an existing demo order as well, so an interrupted seed run can be
  # completed safely without placing a duplicate order.
  demo.fetch(:statuses).each do |status|
    order.transition_to!(status) if order.can_transition_to?(status)
  end
end
