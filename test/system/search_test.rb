require "application_system_test_case"

class SearchTest < ApplicationSystemTestCase
  test "guest finds a product from the header search" do
    visit root_path

    search_for("лина")

    assert_current_path(/q=/)
    assert_selector "h1", text: /каталог/i
    assert_text "Найден 1 товар по запросу «лина»"
    assert_text "Куртка «Лина»"
    assert_no_text "Куртка «Арден»"
  end

  test "a search without results offers to reset the filters" do
    visit products_path

    search_for("телепорт")

    assert_text "Найдено 0 товаров по запросу «телепорт»"
    assert_text "Ничего не найдено"
    assert_text "Измените фильтры."

    click_on "Сбросить фильтры"

    assert_current_path products_path
    assert_text "Найдено 3 товара"
    assert_no_text "Ничего не найдено"
  end

  test "search from a section page searches the whole catalog" do
    visit category_path(categories(:women))

    search_for("арден")

    assert_text "Найден 1 товар по запросу «арден»"
    assert_text "Куртка «Арден»"
  end

  private
    def search_for(query)
      within("header form[role=search]") do
        fill_in "Поиск товаров", with: query
        find("button[type=submit]").click
      end
    end
end
