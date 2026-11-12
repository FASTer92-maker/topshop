require "test_helper"

class OrderItemTest < ActiveSupport::TestCase
  setup do
    @variant = variants(:men_jacket_m_black)
    @order = create_order
  end

  test "is valid with snapshots and a variant" do
    assert build_item.valid?
  end

  test "requires an order" do
    item = OrderItem.new(item_attributes)
    item.order = nil

    assert_not item.valid?
    assert_includes item.errors[:order], "должно существовать"
  end

  test "requires a variant" do
    item = build_item
    item.variant = nil

    assert_not item.valid?
    assert_includes item.errors[:variant], "должно существовать"
  end

  test "requires every snapshot" do
    item = build_item(product_name: "", size: "", color: "")

    assert_not item.valid?
    assert_includes item.errors[:product_name], "не может быть пустым"
    assert_includes item.errors[:size], "не может быть пустым"
    assert_includes item.errors[:color], "не может быть пустым"
  end

  test "requires a unit price" do
    item = build_item(unit_price: nil)

    assert_not item.valid?
    assert_includes item.errors[:unit_price], "не может быть пустым"
  end

  test "unit price cannot be negative" do
    item = build_item(unit_price: -1)

    assert_not item.valid?
    assert item.errors.of_kind?(:unit_price, :greater_than_or_equal_to)
  end

  test "quantity must be a positive integer" do
    [ 0, -1, 1.5, nil ].each do |quantity|
      item = build_item(quantity: quantity)

      assert_not item.valid?, "количество #{quantity.inspect} должно быть недопустимым"
    end
  end

  test "subtotal multiplies the only price by the quantity" do
    item = build_item(quantity: 3)

    assert_equal 38_970, item.subtotal
  end

  test "delegates the product to the variant" do
    item = build_item

    assert_equal products(:men_jacket), item.product
  end

  test "keeps the snapshot after the product and variant change" do
    item = build_item
    item.save!
    products(:men_jacket).update!(name: "Куртка «Новая»", price: 999)
    @variant.update!(color: "Синий", size: "L")

    item.reload
    assert_equal "Куртка «Арден»", item.product_name
    assert_equal "M", item.size
    assert_equal "Чёрный", item.color
    assert_equal 12_990, item.unit_price
    assert_equal 12_990, item.subtotal
  end

  test "is destroyed with the order" do
    order = create_order
    order.order_items.create!(item_attributes.merge(quantity: 2))

    assert_difference -> { OrderItem.count }, -2 do
      order.destroy!
    end
  end

  private
    def item_attributes(overrides = {})
      {
        variant: @variant,
        product_name: "Куртка «Арден»",
        size: "M",
        color: "Чёрный",
        unit_price: 12_990,
        quantity: 1
      }.merge(overrides)
    end

    def build_item(**overrides)
      @order.order_items.build(item_attributes(overrides))
    end

    def create_order
      order = users(:customer).orders.build(
        full_name: "Иван Петров",
        phone: "+7 (999) 123-45-67",
        address: "Москва, ул. Тверская, 1",
        subtotal: 12_990,
        delivery_price: 0,
        total: 12_990
      )
      order.order_items.build(item_attributes)
      order.save!
      order
    end
end
