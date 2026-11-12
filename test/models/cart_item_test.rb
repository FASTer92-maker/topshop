require "test_helper"

class CartItemTest < ActiveSupport::TestCase
  setup do
    @cart = carts(:customer_cart)
    @variant = variants(:men_jacket_m_black)
  end

  def build_item(**attributes)
    CartItem.new(cart: @cart, variant: @variant, quantity: 1, **attributes)
  end

  test "valid with a cart, a variant and a quantity" do
    assert build_item.valid?
  end

  test "requires a cart and a variant" do
    item = CartItem.new

    assert_not item.valid?
    assert_includes item.errors[:cart], "должно существовать"
    assert_includes item.errors[:variant], "должно существовать"
  end

  test "requires a positive integer quantity" do
    item = build_item(quantity: 0)

    assert_not item.valid?
    assert_includes item.errors[:quantity], "должно быть больше 0"

    item.quantity = 1.5

    assert_not item.valid?
    assert_includes item.errors[:quantity], "должно быть целым числом"
  end

  test "allows one row per variant in a cart" do
    CartItem.create!(cart: @cart, variant: @variant, quantity: 1)
    item = build_item

    assert_not item.valid?
    assert item.errors.added?(:variant_id, :taken, value: @variant.id)
  end

  test "allows the same variant in another cart" do
    CartItem.create!(cart: @cart, variant: @variant, quantity: 1)

    assert build_item(cart: carts(:other_customer_cart)).valid?
  end

  test "rejects a quantity above the stock" do
    item = build_item(variant: variants(:men_jacket_m_tabacco), quantity: 3)

    assert_not item.valid?
    assert_includes item.errors[:quantity], "Недостаточно товара на складе (доступно: 2)"
  end

  test "rejects an out-of-stock variant" do
    item = build_item(variant: variants(:sold_out_bag_one_size))

    assert_not item.valid?
    assert_includes item.errors[:quantity], "Недостаточно товара на складе (доступно: 0)"
  end

  test "rejects a variant of a hidden product" do
    item = build_item(variant: variants(:hidden_bag_one_size))

    assert_not item.valid?
    assert_includes item.errors[:quantity], "Товар недоступен"
  end

  test "subtotal multiplies the quantity by the product price" do
    assert_equal 25_980, build_item(quantity: 2).subtotal
  end

  test "available? reflects the stock and the product state" do
    assert build_item.available?
    assert_not build_item(quantity: 6).available?
    assert_not build_item(variant: variants(:sold_out_bag_one_size)).available?
    assert_not build_item(variant: variants(:hidden_bag_one_size)).available?
  end

  test "delegates the product to the variant" do
    assert_equal products(:men_jacket), build_item.product
  end
end
