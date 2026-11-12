require "application_system_test_case"

class CartManagementTest < ApplicationSystemTestCase
  test "guest is asked to sign in" do
    visit cart_path

    assert_current_path new_session_path
    assert_selector "h1", text: /вход/i
  end

  test "empty cart shows the empty state and a catalog link" do
    sign_in_as_customer

    visit cart_path

    assert_text "Корзина пуста."
    assert_link "Перейти в каталог"
    within("header") { assert_selector "#cart_counter", text: /корзина \(0\)/i }
  end

  test "customer changes the quantity without reloading the page" do
    item = carts(:customer_cart).add_variant(variants(:men_jacket_m_black))
    sign_in_as_customer
    visit cart_path
    page.execute_script("window.cartMarker = true")

    within("#cart_item_#{item.id}") { assert_selector "[aria-live='polite']", text: "1" }
    within("#cart_summary") { assert_text "Доставка бесплатная" }

    within("#cart_item_#{item.id}") { find("button[aria-label*='Увеличить']").click }

    within("#cart_item_#{item.id}") { assert_selector "[aria-live='polite']", text: "2" }
    within("header") { assert_selector "#cart_counter", text: /корзина \(2\)/i }
    within("#cart_summary") { assert_text(/25[[:space:]]980/) }

    within("#cart_item_#{item.id}") { find("button[aria-label*='Уменьшить']").click }

    within("#cart_item_#{item.id}") { assert_selector "[aria-live='polite']", text: "1" }
    within("header") { assert_selector "#cart_counter", text: /корзина \(1\)/i }

    assert page.evaluate_script("window.cartMarker"), "страница не должна перезагружаться"
  end

  test "the delivery hint changes when the threshold is reached" do
    cart = carts(:customer_cart)
    variant = cheap_variant(price: 4_000)
    item = cart.add_variant(variant)
    sign_in_as_customer
    visit cart_path

    within("#cart_summary") do
      assert_text(/400[[:space:]]₽/)
      assert_text(/До бесплатной доставки: 6[[:space:]]000/)
    end

    # Each click sends the quantity rendered in the row, so wait for the Turbo
    # Stream to replace the row before clicking again. Two clicks in a row would
    # both send quantity=2 and the second increment would be lost.
    within("#cart_item_#{item.id}") { find("button[aria-label*='Увеличить']").click }
    within("#cart_item_#{item.id}") { assert_selector "[aria-live='polite']", text: "2" }

    within("#cart_item_#{item.id}") { find("button[aria-label*='Увеличить']").click }
    within("#cart_item_#{item.id}") { assert_selector "[aria-live='polite']", text: "3" }

    within("#cart_summary") do
      assert_text "Доставка бесплатная"
      assert_no_text "До бесплатной доставки"
      assert_text "Бесплатно"
    end
    within("#cart_item_#{item.id}") { assert_selector "[aria-live='polite']", text: "3" }
  end

  test "minus at one removes the row and shows the empty state" do
    item = carts(:customer_cart).add_variant(variants(:men_jacket_m_black))
    sign_in_as_customer
    visit cart_path

    within("#cart_item_#{item.id}") { find("button[aria-label*='Уменьшить']").click }

    assert_no_selector "#cart_item_#{item.id}"
    assert_no_selector "#cart_summary"
    assert_text "Корзина пуста."
    assert_text "Товар удалён из корзины"
    within("header") { assert_selector "#cart_counter", text: /корзина \(0\)/i }
  end

  test "customer removes a row with the delete button" do
    item = carts(:customer_cart).add_variant(variants(:women_jacket_s_black))
    sign_in_as_customer
    visit cart_path

    within("#cart_item_#{item.id}") { click_on "Удалить" }

    assert_no_selector "#cart_item_#{item.id}"
    assert_text "Корзина пуста."
    assert_text "Товар удалён из корзины"
  end

  test "an unavailable row is marked and the summary warns" do
    item = carts(:customer_cart).add_variant(variants(:men_jacket_m_black), 2)
    variants(:men_jacket_m_black).update!(stock: 1)
    sign_in_as_customer

    visit cart_path

    within("#cart_item_#{item.id}") do
      assert_text(/Недостаточно товара на складе \(доступно: 1\)/)
      assert_selector "button[disabled]", text: "+"
    end
    within("#cart_summary") { assert_text(/Исправьте количество/) }
  end

  private
    def cheap_variant(price:, stock: 5)
      product = Product.create!(category: categories(:accessories_bags), name: "Ремень", price: price, active: true)
      product.variants.create!(size: "ONE SIZE", color: "Чёрный", stock: stock,
                               sku: "AC-BEL-#{SecureRandom.hex(3)}")
    end

    def sign_in_as_customer(email = "ivan@example.com")
      visit new_session_path
      fill_in "Email", with: email
      fill_in "Пароль", with: "password123"
      click_on "Войти", class: "btn-primary"
      # Turbo sends the form in the background, so wait for the account menu.
      within("header") { assert_selector "summary" }
    end
end
