require "test_helper"

class CartTest < ActiveSupport::TestCase
  setup do
    @cart = carts(:customer_cart)
    @variant = variants(:men_jacket_m_black)
  end

  test "valid with a user" do
    assert @cart.valid?
  end

  test "requires a user" do
    cart = Cart.new

    assert_not cart.valid?
    assert_includes cart.errors[:user], "должно существовать"
  end

  test "one cart per user" do
    cart = Cart.new(user: users(:customer))

    assert_not cart.valid?
    assert cart.errors.added?(:user_id, :taken, value: users(:customer).id)
  end

  test "add_variant creates an item with the given quantity" do
    assert_difference -> { @cart.cart_items.count }, 1 do
      item = @cart.add_variant(@variant, 2)

      assert item.persisted?
      assert_equal 2, item.quantity
    end
  end

  test "add_variant defaults to one item" do
    assert_equal 1, @cart.add_variant(@variant).quantity
  end

  test "add_variant increases the quantity of an existing item" do
    @cart.add_variant(@variant, 2)

    assert_no_difference -> { @cart.cart_items.count } do
      item = @cart.add_variant(@variant, 1)

      assert_equal 3, item.reload.quantity
    end
  end

  test "add_variant keeps a separate row per variant" do
    @cart.add_variant(@variant)
    @cart.add_variant(variants(:men_jacket_m_tabacco))

    assert_equal 2, @cart.cart_items.count
  end

  test "add_variant rejects more than the stock" do
    item = @cart.add_variant(variants(:men_jacket_m_tabacco), 3)

    assert_not item.persisted?
    assert_includes item.errors[:quantity], "Недостаточно товара на складе (доступно: 2)"
    assert_equal 0, @cart.cart_items.count
  end

  test "add_variant rejects the sum when the item already sits in the cart" do
    @cart.add_variant(variants(:men_jacket_m_tabacco), 2)

    item = @cart.add_variant(variants(:men_jacket_m_tabacco), 1)

    assert_includes item.errors[:quantity], "Недостаточно товара на складе (доступно: 2)"
    assert_equal 2, item.reload.quantity
  end

  test "add_variant rejects an out-of-stock variant" do
    item = @cart.add_variant(variants(:sold_out_bag_one_size))

    assert_not item.persisted?
    assert_includes item.errors[:quantity], "Недостаточно товара на складе (доступно: 0)"
  end

  test "add_variant rejects a variant of a hidden product" do
    item = @cart.add_variant(variants(:hidden_bag_one_size))

    assert_not item.persisted?
    assert_includes item.errors[:quantity], "Товар недоступен"
  end

  test "items_count sums the quantities" do
    assert_equal 0, @cart.items_count

    @cart.add_variant(@variant, 2)
    @cart.add_variant(variants(:women_jacket_s_black), 1)

    assert_equal 3, @cart.items_count
  end

  test "subtotal sums quantity times product price" do
    assert_equal 0, @cart.subtotal

    @cart.add_variant(@variant, 2)
    @cart.add_variant(variants(:women_jacket_s_black), 1)

    assert_equal 39_970, @cart.subtotal
  end

  test "cart items are destroyed with the cart" do
    @cart.add_variant(@variant)

    assert_difference -> { CartItem.count }, -1 do
      @cart.destroy!
    end
  end

  test "is destroyed with its user" do
    assert_difference -> { Cart.count }, -1 do
      users(:customer).destroy!
    end
  end
end
