require "application_system_test_case"

class OrderHistoryTest < ApplicationSystemTestCase
  test "customer opens order history from the account menu and sees the status scale" do
    order = place_order
    order.update!(status: :assembled)

    sign_in_as_customer
    find("#account_menu summary").click
    click_on "Мои заказы"

    assert_current_path orders_path
    assert_selector "h1", text: /мои заказы/i
    assert_selector "table"
    assert_text "Заказ №#{order.number}"
    assert_selector "tbody span", text: /собран/i

    click_on "Заказ №#{order.number}"

    assert_current_path order_path(order)
    assert_selector "span", text: /собран/i
    assert_text(/новый/i)
    assert_text(/оплачен/i)
    assert_text(/собран/i)
    assert_text(/отправлен/i)
    assert_text(/доставлен/i)
  end

  private
    def place_order
      cart = carts(:customer_cart)
      cart.add_variant(variants(:men_jacket_m_black), 1)
      Order.place_from_cart!(cart, {
        full_name: "Иван Петров",
        phone: "+7 (999) 123-45-67",
        address: "Москва, ул. Тверская, 1"
      })
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
