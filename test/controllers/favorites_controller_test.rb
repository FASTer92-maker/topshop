require "test_helper"

class FavoritesControllerTest < ActionDispatch::IntegrationTest
  test "guest is asked to sign in on the favourites page" do
    get favorites_path

    assert_redirected_to new_session_path
  end

  test "guest cannot add a product to favourites" do
    assert_no_difference -> { Favorite.count } do
      post product_favorite_path(products(:men_jacket))
    end

    assert_redirected_to new_session_path
  end

  test "index lists only the current user's favourites" do
    sign_in_as users(:customer)

    get favorites_path

    assert_response :success
    assert_select "h1", "Избранное"
    assert_select "article", text: /Куртка «Арден»/
    assert_select "article", text: /Куртка «Лина»/, count: 0
  end

  test "index shows an empty state" do
    sign_in_as users(:other_customer)

    get favorites_path

    assert_response :success
    assert_select "p", text: "В избранном пока пусто"
    assert_select "article", count: 0
  end

  test "create adds the product and replaces the button and the counter" do
    user = users(:other_customer)
    product = products(:men_jacket)
    sign_in_as user

    assert_difference -> { user.favorites.count }, 1 do
      post product_favorite_path(product), as: :turbo_stream
    end

    assert_response :success
    assert_select "turbo-stream[action=replace][target=?]", "favorite_product_#{product.id}"
    assert_select "turbo-stream[action=replace][target=favorites_counter]"
    assert_match(/id="favorites_counter"[^>]*>1</, response.body)
    assert_match(/aria-label="Убрать из избранного"/, response.body)
  end

  test "create twice does not duplicate the favourite" do
    user = users(:other_customer)
    product = products(:men_jacket)
    sign_in_as user
    post product_favorite_path(product), as: :turbo_stream

    assert_no_difference -> { user.favorites.count } do
      post product_favorite_path(product), as: :turbo_stream
    end
  end

  test "destroy removes the current user's favourite" do
    user = users(:customer)
    product = products(:men_jacket)
    sign_in_as user

    assert_difference -> { user.favorites.count }, -1 do
      delete product_favorite_path(product), as: :turbo_stream
    end

    assert_response :success
    assert_select "turbo-stream[action=replace][target=favorites_counter]"
    assert_match(/aria-label="Добавить в избранное"/, response.body)
  end

  test "a favourite of another user cannot be removed" do
    sign_in_as users(:other_customer)

    assert_no_difference -> { Favorite.count } do
      delete product_favorite_path(products(:men_jacket))
    end

    assert_response :not_found
  end

  test "create answers html requests with a redirect" do
    sign_in_as users(:other_customer)

    post product_favorite_path(products(:men_jacket))

    assert_redirected_to favorites_path
  end

  test "an unknown product is not found" do
    sign_in_as users(:other_customer)

    post "/products/unknown-product/favorite"

    assert_response :not_found
  end
end
