require "application_system_test_case"

class CheckoutTest < ApplicationSystemTestCase
  test "customer checks out from the cart" do
    variant = variants(:men_jacket_m_tabacco)

    sign_in_as_customer
    visit product_path(products(:men_jacket))
    pick_size("Табачный", "M")
    click_on "В корзину"

    assert_current_path cart_path
    assert_link "Оформить заказ"

    click_on "Оформить заказ"

    assert_current_path new_order_path
    assert_selector "h1", text: /оформление заказа/i
    assert_field "ФИО", with: "Иван Петров"
    assert_text "Куртка «Арден»"
    assert_text "Бесплатно"

    fill_in "Телефон", with: "+7 (999) 123-45-67"
    fill_in "Адрес", with: "Москва, ул. Тверская, 1"
    fill_in "Комментарий", with: "Позвонить за час"
    click_on "Подтвердить заказ"

    assert_text(/Заказ принят/i)
    assert_text "Оплата имитируется"
    assert_text "Куртка «Арден»"
    assert_text "Табачный"
    assert_text "Иван Петров"
    assert_text "Москва, ул. Тверская, 1"

    order = Order.last
    assert_current_path order_path(order)
    assert_equal 1, variant.reload.stock
    assert_equal 0, carts(:customer_cart).cart_items.count
  end

  test "an unavailable row blocks checkout and redirects back to the cart" do
    carts(:customer_cart).add_variant(variants(:men_jacket_m_black), 2)
    variants(:men_jacket_m_black).update!(stock: 1)
    sign_in_as_customer

    visit cart_path

    assert_no_link "Оформить заказ"
    assert_text(/Исправьте количество/)

    visit new_order_path

    assert_current_path cart_path
    assert_text(/Исправьте количество/)
  end

  test "empty cart cannot be checked out" do
    sign_in_as_customer

    visit new_order_path

    assert_current_path cart_path
    assert_text "Корзина пуста."
    assert_text "Корзина пуста — добавьте товары перед оформлением."
  end

  test "invalid delivery data keeps the customer on the checkout form" do
    carts(:customer_cart).add_variant(variants(:men_jacket_m_black))
    sign_in_as_customer
    visit new_order_path

    fill_in "Телефон", with: "123"
    fill_in "Адрес", with: "Москва"
    click_on "Подтвердить заказ"

    assert_current_path new_order_path
    assert_text(/имеет неверное значение/)
    assert_field "ФИО", with: "Иван Петров"
    assert_equal 0, Order.count
    assert_equal 5, variants(:men_jacket_m_black).reload.stock
  end

  private
    def pick_size(color, size)
      within("[data-size-color='#{color}']") do
        find("label", text: size, exact_text: true).click
      end
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
