require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "renders the home page in Russian" do
    get root_url

    assert_response :success
    assert_select "html[lang=ru]"
    assert_select "title", "Главная · TopShop"
  end

  test "renders the layout: promo bar, header, main and footer" do
    get root_url

    assert_select "body", text: /Бесплатная доставка от 10\s000 ₽/
    assert_select "header a[href=?]", root_path, text: "TopShop"
    assert_select "header nav[aria-label=?]", "Основное меню"
    assert_select "main#main h1", "Одежда на каждый день"
    assert_select "footer", text: /Помощь/
    assert_select "footer", text: /© #{Date.current.year} TopShop/
  end

  test "is public and offers guests to sign in" do
    get root_url

    assert_response :success
    assert_select "header a[href=?]", new_session_path, text: "Войти"
    assert_select "#account_menu", count: 0
  end

  test "shows the account menu to signed in users" do
    sign_in_as users(:customer)

    get root_url

    assert_select "header a[href=?]", new_session_path, count: 0
    assert_select "#account_menu summary", text: /Иван/
    assert_select "#account_menu", text: /ivan@example.com/
    assert_select "#account_menu form[action=?] input[name=_method][value=delete]", session_path
  end

  test "links the hero and the section banners to the catalog" do
    get root_url

    assert_select "main a[href=?]", products_path, text: /Перейти в каталог/
    assert_select "main a[href=?]", category_path(categories(:men)), text: /Мужское/
    assert_select "main a[href=?]", category_path(categories(:women)), text: /Женское/
    assert_select "main a[href=?]", products_path, text: /Смотреть все/
  end

  test "shows the eight newest active products" do
    get root_url

    assert_select "article", count: 3
    assert_select "article", text: /Куртка «Арден»/
    assert_select "article", text: /Сумка «Пусто»/
    assert_select "article", text: /Сумка «Архив»/, count: 0
  end

  test "limits new arrivals to eight products" do
    10.times do |index|
      Product.create!(category: categories(:men_jackets), name: "Новинка #{index}", price: 1000, active: true)
    end

    get root_url

    assert_select "article", count: 8
  end

  test "shows a product card with colours, price and stock state" do
    get root_url

    assert_select "article", text: /Куртка «Арден»/ do
      assert_select "p", text: /Табачный \/ Чёрный/
      assert_select "p", text: /12.990\p{Zs}₽/
    end

    assert_select "article", text: /Сумка «Пусто»/ do
      assert_select "p", text: /Нет в наличии/
    end
  end

  test "shows the empty state while there are no products" do
    Product.destroy_all

    get root_url

    assert_select "main", text: /Скоро здесь появятся товары/
    assert_select "article", count: 0
  end

  test "renders flash messages with a close button" do
    # The flash partial reads from the flash of the current request.
    get root_url, headers: {}, env: { "action_dispatch.request.flash_hash" => ActionDispatch::Flash::FlashHash.new(alert: "Доступ запрещён") }

    assert_select "#flash [role=alert]", text: /Доступ запрещён/
    assert_select "#flash button[data-action='dismiss#close'][aria-label=?]", "Закрыть"
  end
end
