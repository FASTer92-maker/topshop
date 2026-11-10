require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  test "a section shows the products of all its subcategories" do
    get category_path(categories(:men))

    assert_response :success
    assert_select "title", "Мужское · TopShop"
    assert_select "h1", "Мужское"
    assert_select "p", text: "Найден 1 товар"
    assert_select "article", text: /Куртка «Арден»/
  end

  test "a section lists its subcategories as chips" do
    get category_path(categories(:women))

    assert_select "h1", "Женское"
    assert_select "main a[href=?]", category_path(categories(:women_jackets)), text: "Куртки"
    assert_select "main a[href=?]", category_path(categories(:women_skirts)), text: "Юбки"
  end

  test "a section does not show products of other sections" do
    get category_path(categories(:men))

    assert_select "article", text: /Куртка «Лина»/, count: 0
    assert_select "article", text: /Сумка «Пусто»/, count: 0
  end

  test "a subcategory shows only its own products and breadcrumbs" do
    get category_path(categories(:men_jackets))

    assert_response :success
    assert_select "h1", "Куртки"
    assert_select "nav[aria-label=?] a", "Хлебные крошки", text: "Мужское"
    assert_select "article", text: /Куртка «Арден»/
    assert_select "article", text: /Куртка «Лина»/, count: 0
  end

  test "an unknown category returns 404" do
    get "/categories/net-takogo-razdela"

    assert_response :not_found
  end

  test "is public" do
    get category_path(categories(:accessories))

    assert_response :success
  end
end
