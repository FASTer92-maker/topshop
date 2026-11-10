require "application_system_test_case"

class AdminProductsTest < ApplicationSystemTestCase
  test "admin creates a product with an image" do
    sign_in_as_admin

    visit admin_products_path
    assert_text "Товары"

    click_on "Добавить товар"
    fill_in "Название", with: "Сумка «Тест»"
    select "Сумки", from: "Подкатегория"
    fill_in "Цена", with: "4990"
    fill_in "Описание", with: "Плотная сумка из экокожи."
    attach_file "Изображение", file_fixture("product.png").to_s
    click_on "Создать"

    assert_text "Товар создан."
    assert_text(/Сумка «Тест»/i)
    assert_text "Активен"
  end

  test "admin hides a product from the list" do
    sign_in_as_admin

    visit admin_products_path
    within("li", text: "Куртка «Арден»") { click_on "Скрыть" }

    assert_text "Товар обновлён."
    assert_not products(:men_jacket).reload.active?
  end

  test "customer cannot open the products admin" do
    visit new_session_path
    fill_in "Email", with: "ivan@example.com"
    fill_in "Пароль", with: "password123"
    click_on "Войти", class: "btn-primary"
    within("header") { assert_selector "summary", text: "Иван" }

    visit admin_products_path

    assert_text "Доступ запрещён"
  end

  private
    def sign_in_as_admin
      visit new_session_path
      fill_in "Email", with: "admin@example.com"
      fill_in "Пароль", with: "password123"
      click_on "Войти", class: "btn-primary"
      within("header") { assert_selector "summary", text: "Админ" }
    end
end
