require "test_helper"

class CartsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:customer)
  end

  test "guest is asked to sign in" do
    get cart_path

    assert_redirected_to new_session_path
  end

  test "empty cart shows the empty state and a catalog link" do
    sign_in_as @user

    get cart_path

    assert_response :success
    assert_select "h1", text: "Корзина"
    assert_select "#cart_contents", text: /Корзина пуста\./
    assert_select "a", text: "Перейти в каталог"
    assert_select "#cart_summary", count: 0
    assert_select "#cart_counter", text: /Корзина \(0\)/
  end

  test "cart lists the item with its variant, price and the totals" do
    item = carts(:customer_cart).add_variant(variants(:men_jacket_m_black))
    sign_in_as @user

    get cart_path

    assert_response :success
    assert_select "#cart_item_#{item.id}" do
      assert_select "a", text: "Куртка «Арден»"
      assert_select "p", text: "M · Чёрный"
      assert_select "p", text: /12[[:space:]]990/
    end
    assert_select "#cart_summary" do
      assert_select "dt", text: "Товары"
      assert_select "dt", text: "Доставка"
      assert_select "dt", text: "Итого"
      assert_select "dd", text: /12[[:space:]]990/
      assert_select "dd", text: "Бесплатно"
      assert_select "p", text: "Доставка бесплатная"
    end
    assert_select "#cart_counter", text: /Корзина \(1\)/
  end

  test "below the threshold the cart shows the delivery price and the hint" do
    variant = cheap_variant(price: 4_000)
    carts(:customer_cart).add_variant(variant)
    sign_in_as @user

    get cart_path

    assert_select "#cart_summary" do
      assert_select "dd", text: /400[[:space:]]₽/
      assert_select "p", text: /До бесплатной доставки: 6[[:space:]]000/
    end
  end

  test "only the current user's items are shown" do
    carts(:other_customer_cart).add_variant(variants(:women_jacket_s_black))
    sign_in_as @user

    get cart_path

    assert_select "#cart_contents", text: /Корзина пуста\./
    assert_select "a", text: "Куртка «Лина»", count: 0
  end

  test "an unavailable row is marked and blocks checkout" do
    item = carts(:customer_cart).add_variant(variants(:men_jacket_m_black), 2)
    variants(:men_jacket_m_black).update!(stock: 1)
    sign_in_as @user

    get cart_path

    assert_select "#cart_item_#{item.id}" do
      assert_select "p", text: /Недостаточно товара на складе \(доступно: 1\)/
      assert_select "button[disabled]", text: "+"
    end
    assert_select "#cart_summary" do
      assert_select "p", text: /Исправьте количество/
    end
  end

  private
    def cheap_variant(price:, stock: 5)
      product = Product.create!(category: categories(:accessories_bags), name: "Ремень", price: price, active: true)
      product.variants.create!(size: "ONE SIZE", color: "Чёрный", stock: stock,
                               sku: "AC-BEL-#{SecureRandom.hex(3)}")
    end
end
