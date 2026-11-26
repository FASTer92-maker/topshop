require "test_helper"

# The public/404.html, 422.html and 500.html files shadow these paths for direct
# requests, so the controller is exercised through a temporary route.
class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test "404 page uses the storefront design" do
    with_routing do |set|
      set.draw do
        get "/missing-page" => "errors#not_found"
        root "home#index"
      end
      get "/missing-page"
    end

    assert_response :not_found
    assert_select "h1", /Страница не найдена/
    assert_select "a", /На главную/
  end

  test "422 page uses the storefront design" do
    with_routing do |set|
      set.draw do
        get "/stale-page" => "errors#unprocessable_entity"
        root "home#index"
      end
      get "/stale-page"
    end

    assert_response :unprocessable_entity
    assert_select "h1", /Запрос не может быть обработан/
  end

  test "500 page uses the storefront design" do
    with_routing do |set|
      set.draw do
        get "/broken-page" => "errors#internal_server_error"
        root "home#index"
      end
      get "/broken-page"
    end

    assert_response :internal_server_error
    assert_select "h1", /Что-то пошло не так/
  end
end
