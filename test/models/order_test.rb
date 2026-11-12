require "test_helper"

class OrderTest < ActiveSupport::TestCase
  CUSTOMER_ATTRIBUTES = {
    full_name: "Иван Петров",
    phone: "+7 (999) 123-45-67",
    address: "Москва, ул. Тверская, 1",
    comment: "Позвонить за час"
  }.freeze

  setup do
    @user = users(:customer)
    @cart = carts(:customer_cart)
    @variant = variants(:men_jacket_m_black)
  end

  # --- Validations ---------------------------------------------------------

  test "is valid with delivery data and an item" do
    assert build_order.valid?
  end

  test "requires a user" do
    order = build_order
    order.user = nil

    assert_not order.valid?
    assert_includes order.errors[:user], "должно существовать"
  end

  test "status defaults to pending" do
    assert_equal "pending", build_order.status
    assert build_order.pending?
  end

  test "assigns a formatted number on create" do
    order = create_order

    assert_match(/\AORD-#{Date.current.strftime('%Y%m%d')}-[0-9A-F]{4}\z/, order.number)
  end

  test "keeps a given number" do
    order = create_order(number: "ORD-CUSTOM-0001")

    assert_equal "ORD-CUSTOM-0001", order.number
  end

  test "number is unique" do
    existing = create_order
    order = build_order(number: existing.number)

    assert_not order.valid?
    assert order.errors.added?(:number, :taken, value: existing.number)
  end

  test "requires the customer's name, phone and address" do
    order = build_order(full_name: "", phone: "", address: "")

    assert_not order.valid?
    assert_includes order.errors[:full_name], "не может быть пустым"
    assert_includes order.errors[:phone], "не может быть пустым"
    assert_includes order.errors[:address], "не может быть пустым"
  end

  test "full name is limited to 100 characters" do
    assert build_order(full_name: "Ф" * 100).valid?

    order = build_order(full_name: "Ф" * 101)
    assert_not order.valid?
    assert order.errors.of_kind?(:full_name, :too_long)
  end

  test "accepts common phone formats" do
    [
      "+7 (999) 123-45-67",
      "+79991234567",
      "8 999 123 45 67",
      "9991234567",
      "+7(999)123-45-67"
    ].each do |phone|
      assert build_order(phone: phone).valid?, "ожидался допустимый телефон: #{phone}"
    end
  end

  test "rejects an invalid phone" do
    [ "12345", "abc", "+7 (999) 123-45-67 доб. 1", "+7 (999) 123 45 67!", "1" * 21 ].each do |phone|
      order = build_order(phone: phone)

      assert_not order.valid?, "ожидался недопустимый телефон: #{phone}"
      assert order.errors.of_kind?(:phone, :invalid), "нет ошибки формата для #{phone}"
    end
  end

  test "comment is optional" do
    assert build_order(comment: nil).valid?
  end

  test "amounts cannot be negative" do
    order = build_order(subtotal: -1, delivery_price: 0, total: -1)

    assert_not order.valid?
    assert order.errors.of_kind?(:subtotal, :greater_than_or_equal_to)
    assert order.errors.of_kind?(:total, :greater_than_or_equal_to)
  end

  test "total must equal subtotal plus delivery" do
    order = build_order(total: 1)

    assert_not order.valid?
    assert_includes order.errors[:total], "должно быть равно сумме товаров и доставки"
  end

  test "requires at least one order item" do
    order = build_order
    order.order_items.clear

    assert_not order.valid?
    assert_includes order.errors[:order_items], "не может быть пустым"
  end

  # --- place_from_cart! ----------------------------------------------------

  test "place_from_cart! creates an order with snapshots and decrements stock" do
    jacket = @cart.add_variant(@variant, 2)
    women_jacket = @cart.add_variant(variants(:women_jacket_s_black))

    order = nil
    assert_difference -> { Order.count }, 1 do
      assert_difference -> { OrderItem.count }, 2 do
        order = Order.place_from_cart!(@cart, CUSTOMER_ATTRIBUTES)
      end
    end

    assert order.persisted?
    assert_equal @user, order.user
    assert order.pending?
    assert_match(/\AORD-\d{8}-[0-9A-F]{4}\z/, order.number)
    assert_equal "Иван Петров", order.full_name
    assert_equal "+7 (999) 123-45-67", order.phone
    assert_equal "Москва, ул. Тверская, 1", order.address
    assert_equal "Позвонить за час", order.comment

    # 2 × 12 990 + 13 990, delivery is free above 10 000.
    assert_equal 39_970, order.subtotal
    assert_equal 0, order.delivery_price
    assert_equal 39_970, order.total
    assert_equal 3, order.items_count

    first = order.order_items.find_by!(variant: @variant)
    assert_equal "Куртка «Арден»", first.product_name
    assert_equal "M", first.size
    assert_equal "Чёрный", first.color
    assert_equal 12_990, first.unit_price
    assert_equal 2, first.quantity
    assert_equal 25_980, first.subtotal

    second = order.order_items.find_by!(variant: variants(:women_jacket_s_black))
    assert_equal "Куртка «Лина»", second.product_name
    assert_equal "S", second.size
    assert_equal "Чёрный", second.color
    assert_equal 13_990, second.unit_price
    assert_equal 1, second.quantity

    assert_equal 3, @variant.reload.stock
    assert_equal 3, variants(:women_jacket_s_black).reload.stock
    assert_empty @cart.reload.cart_items
    assert jacket.persisted? # cart rows are removed, not the checked-out copies
    assert women_jacket.persisted?
  end

  test "place_from_cart! snapshots survive later catalog changes" do
    @cart.add_variant(@variant, 2)
    order = Order.place_from_cart!(@cart, CUSTOMER_ATTRIBUTES)
    item = order.order_items.first

    products(:men_jacket).update!(name: "Куртка «Новая»", price: 999)
    @variant.update!(color: "Синий")

    item.reload
    assert_equal "Куртка «Арден»", item.product_name
    assert_equal "Чёрный", item.color
    assert_equal 12_990, item.unit_price
    assert_equal 25_980, item.subtotal
    assert_equal 25_980, order.reload.subtotal
    assert_equal 25_980, order.total
  end

  test "place_from_cart! charges delivery below 10 000" do
    @cart.add_variant(cheap_variant(price: 4_000))

    order = Order.place_from_cart!(@cart, CUSTOMER_ATTRIBUTES)

    assert_equal 4_000, order.subtotal
    assert_equal Delivery::PRICE, order.delivery_price
    assert_equal 4_400, order.total
  end

  test "place_from_cart! makes delivery free exactly at 10 000" do
    @cart.add_variant(cheap_variant(price: 10_000))

    order = Order.place_from_cart!(@cart, CUSTOMER_ATTRIBUTES)

    assert_equal 10_000, order.subtotal
    assert_equal 0, order.delivery_price
    assert_equal 10_000, order.total
  end

  test "place_from_cart! raises EmptyCartError for an empty cart" do
    assert_no_difference [ -> { Order.count }, -> { OrderItem.count } ] do
      assert_raises(Order::EmptyCartError) do
        Order.place_from_cart!(@cart, CUSTOMER_ATTRIBUTES)
      end
    end
  end

  test "place_from_cart! rolls back everything when stock runs out" do
    @cart.add_variant(@variant, 2)
    @cart.add_variant(variants(:women_jacket_s_black), 1)
    variants(:women_jacket_s_black).update!(stock: 0)

    error = nil
    assert_no_difference [ -> { Order.count }, -> { OrderItem.count } ] do
      error = assert_raises(Order::InsufficientStockError) do
        Order.place_from_cart!(@cart, CUSTOMER_ATTRIBUTES)
      end
    end

    assert_equal variants(:women_jacket_s_black), error.variant
    assert_match "Куртка «Лина»", error.message
    assert_match "доступно: 0", error.message

    # The first, available variant was already decremented before the failure,
    # so this asserts the rollback, not just the pre-check.
    assert_equal 5, @variant.reload.stock
    assert_equal 0, variants(:women_jacket_s_black).reload.stock
    assert_equal 2, @cart.cart_items.count
    assert_equal [ 2, 1 ], @cart.cart_items.order(:id).pluck(:quantity)
  end

  test "place_from_cart! rolls back a partially placed order" do
    @cart.add_variant(@variant, 2)
    @cart.add_variant(variants(:women_jacket_s_black), 1)

    # The second variant is sold out: a full rollback must undo the first one.
    variants(:women_jacket_s_black).update!(stock: 0)

    assert_raises(Order::InsufficientStockError) do
      Order.place_from_cart!(@cart, CUSTOMER_ATTRIBUTES)
    end

    assert_equal 5, @variant.reload.stock
    assert_equal 2, @cart.cart_items.count
    assert_equal 0, Order.where(user: @user).count
  end

  test "place_from_cart! with an out-of-stock variant keeps the stock" do
    @cart.add_variant(@variant)
    @variant.update!(stock: 0)

    assert_raises(Order::InsufficientStockError) do
      Order.place_from_cart!(@cart, CUSTOMER_ATTRIBUTES)
    end

    assert_equal 0, @variant.reload.stock
    assert_equal 1, @cart.cart_items.count
    assert_equal 0, Order.count
  end

  test "place_from_cart! rejects a hidden product without touching stock" do
    @cart.add_variant(@variant)
    products(:men_jacket).update!(active: false)

    error = assert_raises(Order::InsufficientStockError) do
      Order.place_from_cart!(@cart, CUSTOMER_ATTRIBUTES)
    end

    assert_match "Товар недоступен", error.message
    assert_equal 5, @variant.reload.stock
    assert_equal 1, @cart.cart_items.count
    assert_equal 0, Order.count
  end

  test "place_from_cart! rolls back when the delivery data is invalid" do
    @cart.add_variant(@variant, 2)

    assert_no_difference [ -> { Order.count }, -> { OrderItem.count } ] do
      assert_raises(ActiveRecord::RecordInvalid) do
        Order.place_from_cart!(@cart, CUSTOMER_ATTRIBUTES.merge(phone: "123"))
      end
    end

    assert_equal 5, @variant.reload.stock
    assert_equal 2, @cart.cart_items.first.quantity
    assert_equal 0, Order.count
  end

  test "place_from_cart! clears the cart, so it cannot run twice" do
    @cart.add_variant(@variant)
    Order.place_from_cart!(@cart, CUSTOMER_ATTRIBUTES)

    assert_raises(Order::EmptyCartError) do
      Order.place_from_cart!(@cart, CUSTOMER_ATTRIBUTES)
    end

    assert_equal 1, Order.count
    assert_equal 0, @cart.cart_items.count
  end

  # --- Status transitions --------------------------------------------------

  test "lists the allowed transitions for every status" do
    assert_equal %w[paid cancelled], build_order(status: :pending).available_transitions
    assert_equal %w[assembled cancelled], build_order(status: :paid).available_transitions
    assert_equal %w[shipped cancelled], build_order(status: :assembled).available_transitions
    assert_equal %w[delivered], build_order(status: :shipped).available_transitions
    assert_equal [], build_order(status: :delivered).available_transitions
    assert_equal [], build_order(status: :cancelled).available_transitions
  end

  test "can_transition_to? accepts strings and symbols" do
    order = build_order

    assert order.can_transition_to?("paid")
    assert order.can_transition_to?(:paid)
    assert order.can_transition_to?(:cancelled)
    assert_not order.can_transition_to?(:assembled)
    assert_not order.can_transition_to?(:shipped)
    assert_not order.can_transition_to?(:delivered)
    assert_not order.can_transition_to?(:lost)
  end

  test "transition_to! walks the happy path" do
    order = create_order

    order.transition_to!(:paid)
    assert order.reload.paid?

    order.transition_to!("assembled")
    assert order.reload.assembled?

    order.transition_to!("shipped")
    assert order.reload.shipped?

    order.transition_to!("delivered")
    assert order.reload.delivered?
  end

  test "transition_to! rejects a forbidden transition" do
    order = create_order

    error = assert_raises(Order::InvalidTransitionError) { order.transition_to!(:shipped) }

    assert_match "pending", error.message
    assert_match "shipped", error.message
    assert order.reload.pending?
  end

  test "transition_to! rejects every forbidden transition" do
    forbidden = {
      pending: %w[assembled shipped delivered],
      paid: %w[pending shipped delivered],
      assembled: %w[pending paid delivered],
      shipped: %w[pending paid assembled cancelled],
      delivered: %w[pending paid assembled shipped cancelled],
      cancelled: %w[pending paid assembled shipped delivered]
    }

    forbidden.each do |current, targets|
      order = create_order(status: current)

      targets.each do |target|
        assert_raises(Order::InvalidTransitionError, "#{current} → #{target} должен быть запрещён") do
          order.transition_to!(target)
        end
        assert_equal current.to_s, order.reload.status
      end
    end
  end

  test "transition_to! rejects an unknown status" do
    order = create_order

    assert_raises(Order::InvalidTransitionError) { order.transition_to!(:lost) }
    assert order.reload.pending?
  end

  # --- Cancellation --------------------------------------------------------

  test "cancel! returns the stock and marks the order cancelled" do
    order = create_order(quantity: 2)

    assert_equal 5, @variant.reload.stock
    order.cancel!

    assert order.reload.cancelled?
    assert_equal 7, @variant.reload.stock
  end

  test "cancel! returns the stock of every item" do
    order = create_order(quantity: 2)
    order.order_items.create!(
      variant: variants(:women_jacket_s_black),
      product_name: "Куртка «Лина»",
      size: "S",
      color: "Чёрный",
      unit_price: 13_990,
      quantity: 3
    )

    order.cancel!

    assert_equal 7, @variant.reload.stock
    assert_equal 7, variants(:women_jacket_s_black).reload.stock
  end

  test "cancel! works from paid and assembled" do
    %i[paid assembled].each do |status|
      order = create_order(status: status)
      stock_before = @variant.reload.stock

      order.cancel!

      assert order.reload.cancelled?, "заказ в статусе #{status} должен отменяться"
      assert_equal stock_before + 1, @variant.reload.stock
    end
  end

  test "transition_to! cancelled delegates to cancel!" do
    order = create_order(quantity: 2)

    order.transition_to!("cancelled")

    assert order.reload.cancelled?
    assert_equal 7, @variant.reload.stock
  end

  test "a cancelled order cannot be cancelled again" do
    order = create_order(quantity: 2)
    order.cancel!

    assert_raises(Order::InvalidTransitionError) { order.cancel! }
    assert_equal 7, @variant.reload.stock
    assert order.reload.cancelled?
  end

  test "a shipped order cannot be cancelled" do
    order = create_order(status: :shipped)

    assert_raises(Order::InvalidTransitionError) { order.cancel! }

    assert_equal 5, @variant.reload.stock
    assert order.reload.shipped?
  end

  # --- Scopes and counters -------------------------------------------------

  test "items_count sums the quantities" do
    order = create_order(quantity: 2)
    order.order_items.create!(
      variant: variants(:women_jacket_s_black),
      product_name: "Куртка «Лина»",
      size: "S",
      color: "Чёрный",
      unit_price: 13_990,
      quantity: 3
    )

    assert_equal 5, order.items_count
  end

  test "recent orders newest first" do
    older = create_order
    newer = create_order
    older.update_column(:created_at, 2.days.ago)

    assert_equal [ newer.id, older.id ], Order.recent.ids
  end

  test "not_cancelled excludes cancelled orders" do
    active = create_order
    cancelled = create_order
    cancelled.update!(status: :cancelled)

    assert_equal [ active.id ], Order.not_cancelled.ids
  end

  test "revenue sums the totals of active orders" do
    create_order
    cancelled = create_order
    cancelled.update!(status: :cancelled)

    assert_equal 12_990, Order.revenue
  end

  test "revenue is zero without active orders" do
    assert_equal 0, Order.revenue
  end

  # --- Dependencies --------------------------------------------------------

  test "order items are destroyed with the order" do
    order = create_order(quantity: 2)

    assert_difference -> { OrderItem.count }, -1 do
      order.destroy!
    end
  end

  test "a user with orders cannot be destroyed" do
    create_order

    assert_not @user.destroy
    assert @user.persisted?
    assert @user.errors[:base].any?
  end

  test "a variant from an order cannot be destroyed" do
    create_order

    assert_not @variant.destroy
    assert @variant.persisted?
  end

  private
    def build_order(quantity: 1, variant: @variant, **attributes)
      product = variant.product
      subtotal = product.price * quantity
      delivery = Delivery.price_for(subtotal)

      order = @user.orders.build(
        CUSTOMER_ATTRIBUTES.merge(
          subtotal: subtotal,
          delivery_price: delivery,
          total: subtotal + delivery
        ).merge(attributes)
      )
      order.order_items.build(item_attributes(variant, quantity))
      order
    end

    def create_order(**options)
      build_order(**options).tap(&:save!)
    end

    def item_attributes(variant, quantity)
      {
        variant: variant,
        product_name: variant.product.name,
        size: variant.size,
        color: variant.color,
        unit_price: variant.product.price,
        quantity: quantity
      }
    end

    def cheap_variant(price:, stock: 5)
      product = Product.create!(category: categories(:accessories_bags), name: "Ремень",
                                price: price, active: true)
      product.variants.create!(size: "ONE SIZE", color: "Чёрный", stock: stock,
                               sku: "AC-BEL-#{SecureRandom.hex(3)}")
    end
end
