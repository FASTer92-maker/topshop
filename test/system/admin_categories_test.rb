require "application_system_test_case"

class AdminCategoriesTest < ApplicationSystemTestCase
  test "admin creates a section and a subcategory" do
    sign_in_as_admin

    visit admin_categories_path
    assert_text "Категории"
    assert_text "Мужское"
    assert_text "Куртки"

    click_on "Добавить категорию"
    fill_in "Название", with: "Распродажа"
    click_on "Создать"

    assert_text "Категория создана."
    assert_text "Распродажа"

    click_on "Добавить категорию"
    select "Распродажа", from: "Раздел"
    fill_in "Название", with: "Зимняя одежда"
    click_on "Создать"

    assert_text "Категория создана."
    assert_text "Зимняя одежда"
  end

  test "customer cannot open the admin panel" do
    visit new_session_path
    fill_in "Email", with: "ivan@example.com"
    fill_in "Пароль", with: "password123"
    click_on "Войти", class: "btn-primary"
    within("header") { assert_selector "summary", text: "Иван" }

    visit admin_categories_path

    assert_text "Доступ запрещён"
    assert_no_text "Добавить категорию"
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
