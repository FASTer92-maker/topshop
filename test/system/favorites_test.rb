require "application_system_test_case"

class FavoritesTest < ApplicationSystemTestCase
  test "guest is redirected to sign in from the heart" do
    visit product_path(products(:men_jacket))

    find("button[aria-label='Добавить в избранное']").click

    assert_current_path new_session_path
    assert_selector "h1", text: /вход/i
  end

  test "customer toggles a favourite without reloading the page" do
    sign_in_as_customer
    visit product_path(products(:men_jacket))
    page.execute_script("window.favoritesMarker = true")

    within("header") { assert_selector "#favorites_counter", text: "1" }

    find("button[aria-label='Убрать из избранного']").click
    within("header") { assert_selector "#favorites_counter", text: "0" }
    assert_selector "button[aria-label='Добавить в избранное']"

    find("button[aria-label='Добавить в избранное']").click
    within("header") { assert_selector "#favorites_counter", text: "1" }
    assert_selector "button[aria-label='Убрать из избранного']"

    assert page.evaluate_script("window.favoritesMarker"), "страница не должна перезагружаться"
  end

  test "customer toggles a favourite from a catalog card" do
    sign_in_as_customer
    visit products_path

    within("article", text: "Куртка «Лина»") do
      find("button[aria-label='Добавить в избранное']").click
    end

    within("header") { assert_selector "#favorites_counter", text: "2" }

    visit favorites_path

    assert_text "Куртка «Арден»"
    assert_text "Куртка «Лина»"
  end

  test "favourites page shows only the customer's products" do
    sign_in_as_customer

    visit favorites_path

    assert_selector "h1", text: /избранное/i
    assert_text "Куртка «Арден»"
    assert_no_text "Куртка «Лина»"
  end

  test "empty favourites page shows the empty state" do
    sign_in_as_customer("maria@example.com")

    visit favorites_path

    assert_text "В избранном пока пусто"
  end

  test "a hidden favourite is marked as unavailable and has no link" do
    Favorite.create!(user: users(:customer), product: products(:hidden_product))
    sign_in_as_customer

    visit favorites_path

    within("article", text: "Сумка «Архив»") do
      assert_text(/нет в продаже/i)
      assert_no_selector "a"
    end
  end

  private
    def sign_in_as_customer(email = "ivan@example.com")
      visit new_session_path
      fill_in "Email", with: email
      fill_in "Пароль", with: "password123"
      click_on "Войти", class: "btn-primary"
      # Turbo sends the form in the background, so wait for the account menu.
      within("header") { assert_selector "summary" }
    end
end
