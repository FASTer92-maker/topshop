require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "index lists active products with their colours and prices" do
    get products_path

    assert_response :success
    assert_select "title", "Каталог · TopShop"
    assert_select "h1", "Каталог"
    assert_select "p", text: "Найдено 3 товара"
    assert_select "article", count: 3
    assert_select "article", text: /Куртка «Арден»/
    assert_select "article", text: /Табачный \/ Чёрный/
    assert_select "article", text: /12.990\p{Zs}₽/
    assert_select "article", text: /Нет в наличии/
  end

  test "index hides inactive products" do
    get products_path

    assert_select "article", text: /Сумка «Архив»/, count: 0
  end

  test "index paginates twelve products per page" do
    13.times do |index|
      Product.create!(category: categories(:men_jackets), name: "Товар #{index}", price: 1000, active: true)
    end

    get products_path

    assert_select "p", text: "Найдено 16 товаров"
    assert_select "article", count: 12
    assert_select "a[href=?]", products_path(page: 2)

    get products_path(page: 2)

    assert_response :success
    assert_select "article", count: 4
  end

  test "header menu links every section" do
    get products_path

    assert_select "header nav[aria-label=?] a", "Основное меню", text: "Все"
    assert_select "header nav a[href=?]", category_path(categories(:men)), text: "Мужское"
    assert_select "header nav a[href=?]", category_path(categories(:women)), text: "Женское"
    assert_select "header nav a[href=?]", category_path(categories(:accessories)), text: "Аксессуары"
  end

  test "is public" do
    get products_path

    assert_response :success
  end

  test "search in the header points to the catalog" do
    get root_path

    assert_select "header form[role=search][action=?]", products_path do
      assert_select "input[name=q]"
      assert_select "button[type=submit][aria-label=?]", "Найти"
    end
  end

  test "the query filters products by name and is shown in the counter" do
    get products_path, params: { q: "лина" }

    assert_response :success
    assert_select "p", text: "Найден 1 товар по запросу «лина»"
    assert_select "article", text: /Куртка «Лина»/
    assert_select "article", text: /Куртка «Арден»/, count: 0
  end

  test "the query is escaped and cannot match everything with a wildcard" do
    get products_path, params: { q: "%" }

    assert_response :success
    assert_select "article", count: 1
    assert_select "p", text: /по запросу «%»/
  end

  test "filters by size, colour and price" do
    get products_path, params: { size: "M", color: "Чёрный", price_from: "10000" }

    assert_select "article", count: 1
    assert_select "article", text: /Куртка «Арден»/
  end

  test "a size that is out of stock finds nothing" do
    get products_path, params: { size: "L" }

    assert_select "article", count: 0
    assert_select "p", text: "Ничего не найдено"
    assert_select "a[href=?]", products_path, text: "Сбросить фильтры"
  end

  test "the in-stock checkbox hides sold out products" do
    get products_path, params: { in_stock: "1" }

    assert_select "article", text: /Сумка «Пусто»/, count: 0
    assert_select "article", count: 2
  end

  test "malformed filter values are ignored" do
    get products_path, params: { size: "XXXL", price_from: "abc", price_to: "-5", sort: "price; DROP TABLE" }

    assert_response :success
    assert_select "article", count: 3
  end

  test "sorting by price puts the cheapest product first" do
    get products_path, params: { sort: "price_asc" }

    assert_equal "Сумка «Пусто»", css_select("article h3").first.text
  end

  test "pagination keeps the filters in its links" do
    13.times do |index|
      Product.create!(category: categories(:men_jackets), name: "Товар #{index}", price: 1000, active: true)
    end

    get products_path, params: { q: "товар" }

    assert_select "a[href*=?][href*=?]", "page=2", "q="
  end
end
