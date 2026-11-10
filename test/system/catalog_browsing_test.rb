require "application_system_test_case"

class CatalogBrowsingTest < ApplicationSystemTestCase
  test "guest browses a section and then a subcategory" do
    visit root_path
    assert_text "НОВИНКИ"

    within("header nav") { click_on "Мужское" }

    assert_selector "h1", text: /мужское/i
    assert_text "Найден 1 товар"
    assert_text "Куртка «Арден»"
    assert_text "Табачный / Чёрный"

    click_on "Куртки"

    assert_selector "h1", text: /куртки/i
    assert_text "Куртка «Арден»"
    assert_no_text "Куртка «Лина»"
  end

  test "guest opens the whole catalog from the header" do
    visit root_path

    within("header nav") { click_on "Все" }

    assert_selector "h1", text: /каталог/i
    assert_text "Найдено 3 товара"
    assert_text "Сумка «Пусто»"
    assert_text(/нет в наличии/i)
  end
end
