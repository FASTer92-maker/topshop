require "application_system_test_case"

class AdminOrdersTest < ApplicationSystemTestCase
  test "admin moves an order through statuses without reloading the page" do
    order = place_order
    sign_in_as_admin

    visit admin_order_path(order)

    within("#order_status") { assert_text(/новый/i) }
    assert_button "Перевести в «Оплачен»"
    assert_no_button "Перевести в «Собран»"

    # The marker survives Turbo Stream updates and disappears on a full reload.
    page.execute_script("window.__orderPageMarker = true")

    click_on "Перевести в «Оплачен»"

    assert_text "Статус заказа изменён: Оплачен."
    within("#order_status") { assert_text(/оплачен/i) }
    assert_button "Перевести в «Собран»"
    assert_no_button "Перевести в «Оплачен»"
    assert_equal true, page.evaluate_script("window.__orderPageMarker")

    click_on "Перевести в «Собран»"

    assert_text "Статус заказа изменён: Собран."
    within("#order_status") { assert_text(/собран/i) }
    assert_button "Перевести в «Отправлен»"
    assert_equal true, page.evaluate_script("window.__orderPageMarker")
    assert_equal "assembled", order.reload.status
  end

  test "admin cancels an order and its stock returns" do
    variant = variants(:men_jacket_m_black)
    order = place_order(quantity: 2)
    assert_equal 3, variant.reload.stock

    sign_in_as_admin
    visit admin_order_path(order)

    accept_confirm { click_on "Отменить заказ" }

    assert_text "Статус заказа изменён: Отменён."
    within("#order_status") { assert_text(/отменён/i) }
    assert_no_button "Отменить заказ"
    assert_equal 5, variant.reload.stock
  end

  test "admin filters the orders list by status tab" do
    paid_order = place_order
    paid_order.update!(status: :paid)
    pending_order = place_order

    sign_in_as_admin
    visit admin_orders_path

    assert_text paid_order.number
    assert_text pending_order.number

    click_on "Оплачен (1)"

    assert_current_path admin_orders_path(status: "paid")
    assert_text paid_order.number
    assert_no_text pending_order.number
  end

  private
    def place_order(quantity: 1)
      cart = carts(:customer_cart)
      cart.add_variant(variants(:men_jacket_m_black), quantity)
      Order.place_from_cart!(cart, {
        full_name: "Иван Петров",
        phone: "+7 (999) 123-45-67",
        address: "Москва, ул. Тверская, 1"
      })
    end

    def sign_in_as_admin
      visit new_session_path
      fill_in "Email", with: "admin@example.com"
      fill_in "Пароль", with: "password123"
      click_on "Войти", class: "btn-primary"
      within("header") { assert_selector "summary", text: "Админ" }
    end
end
