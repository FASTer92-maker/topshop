require "application_system_test_case"

class AddToCartTest < ApplicationSystemTestCase
  test "guest is asked to sign in from the add to cart button" do
    visit product_path(products(:men_jacket))
    pick_size("Табачный", "M")

    click_on "В корзину"

    assert_current_path new_session_path
    assert_selector "h1", text: /вход/i
  end

  test "customer adds a size and the counter changes without reloading" do
    sign_in_as_customer
    visit product_path(products(:men_jacket))
    pick_size("Табачный", "M")
    page.execute_script("window.cartMarker = true")

    within("header") { assert_selector "#cart_counter", text: /корзина \(0\)/i }

    click_on "В корзину"
    within("header") { assert_selector "#cart_counter", text: /корзина \(1\)/i }
    assert_text "Товар добавлен в корзину"

    click_on "В корзину"
    within("header") { assert_selector "#cart_counter", text: /корзина \(2\)/i }

    assert page.evaluate_script("window.cartMarker"), "страница не должна перезагружаться"
  end

  test "customer cannot add more than the stock" do
    sign_in_as_customer
    visit product_path(products(:men_jacket))
    pick_size("Табачный", "M")

    click_on "В корзину"
    click_on "В корзину"
    within("header") { assert_selector "#cart_counter", text: /корзина \(2\)/i }

    click_on "В корзину"

    assert_text "Недостаточно товара на складе (доступно: 2)"
    within("header") { assert_selector "#cart_counter", text: /корзина \(2\)/i }
  end

  test "customer is asked to choose a size" do
    sign_in_as_customer
    visit product_path(products(:men_jacket))
    page.execute_script("window.cartMarker = true")

    click_on "В корзину"

    assert_text "Выберите размер"
    within("header") { assert_selector "#cart_counter", text: /корзина \(0\)/i }
    assert page.evaluate_script("window.cartMarker"), "запрос без размера не должен отправляться"
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
