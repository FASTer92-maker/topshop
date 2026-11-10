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
end
