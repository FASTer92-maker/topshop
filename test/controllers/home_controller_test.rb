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

  test "shows the empty state while there are no products" do
    get root_url

    assert_select "main", text: /Скоро здесь появятся товары/
  end

  test "renders flash messages with a close button" do
    # The flash partial reads from the flash of the current request.
    get root_url, headers: {}, env: { "action_dispatch.request.flash_hash" => ActionDispatch::Flash::FlashHash.new(alert: "Доступ запрещён") }

    assert_select "#flash [role=alert]", text: /Доступ запрещён/
    assert_select "#flash button[data-action='dismiss#close'][aria-label=?]", "Закрыть"
  end
end
