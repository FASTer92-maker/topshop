require "application_system_test_case"

class FilterTest < ApplicationSystemTestCase
  test "a size filter updates only the grid and the url" do
    visit products_path

    assert_text "Найдено 3 товара"

    select "S", from: "Размер"

    assert_current_path(/size=S/)
    assert_text "Найден 1 товар"
    assert_text "Куртка «Лина»"
    assert_no_text "Куртка «Арден»"
  end

  test "sorting by price puts the most expensive product first" do
    visit products_path

    select "Сначала дорогие", from: "Сортировка"

    assert_current_path(/sort=price_desc/)
    assert_selector "li:first-child article h3", text: "Куртка «Лина»"
  end

  test "the in-stock checkbox hides sold out products" do
    visit products_path

    check "Только в наличии"

    assert_current_path(/in_stock=1/)
    assert_text "Найдено 2 товара"
    assert_no_text "Сумка «Пусто»"
  end

  test "price range and stock filters combine" do
    visit products_path

    fill_in "price_to", with: "7000"
    check "Только в наличии"

    assert_text "Ничего не найдено"
    assert_text "Измените фильтры."

    click_on "Сбросить фильтры"

    assert_current_path products_path
    assert_text "Найдено 3 товара"
  end

  test "the reset link clears every filter" do
    visit products_path(size: "S")

    assert_text "Найден 1 товар"

    click_on "Сбросить"

    assert_current_path products_path
    assert_text "Найдено 3 товара"
  end
end
