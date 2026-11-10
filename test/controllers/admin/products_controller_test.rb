require "test_helper"

class Admin::ProductsControllerTest < ActionDispatch::IntegrationTest
  test "guest is asked to sign in" do
    get admin_products_path

    assert_redirected_to new_session_path
  end

  test "customer is denied access" do
    sign_in_as users(:customer)

    get admin_products_path

    assert_redirected_to root_path
  end

  test "index lists products with their category" do
    sign_in_as users(:admin)

    get admin_products_path

    assert_response :success
    assert_select "h1", "Товары"
    assert_select "a", text: "Добавить товар"
    assert_select "a", text: "Куртка «Арден»"
    assert_select "p", text: "Мужское › Куртки"
  end

  test "index searches by name" do
    sign_in_as users(:admin)

    get admin_products_path, params: { q: "Арден" }

    assert_select "a", text: "Куртка «Арден»"
    assert_select "a", text: "Куртка «Лина»", count: 0
  end

  test "index searches by variant sku" do
    sign_in_as users(:admin)

    get admin_products_path, params: { q: "ZJ-LNA-CHE-S" }

    assert_select "a", text: "Куртка «Арден»", count: 0
    assert_select "a", text: "Куртка «Лина»"
  end

  test "new renders the form with grouped subcategories" do
    sign_in_as users(:admin)

    get new_admin_product_path

    assert_response :success
    assert_select "h1", "Новый товар"
    assert_select "input[name='product[name]']"
    assert_select "select[name='product[category_id]'] optgroup[label='Мужское'] option", text: "Куртки"
    assert_select "input[name='product[price]']"
    assert_select "input[name='product[image]'][type='file']"
  end

  test "create adds a product with an image and a generated slug" do
    sign_in_as users(:admin)

    assert_difference "Product.count", 1 do
      post admin_products_path, params: { product: {
        name: "Плащ «Тест»",
        category_id: categories(:men_jackets).id,
        price: "9990",
        description: "Тёплый плащ.",
        active: "1",
        image: fixture_file_upload("product.png", "image/png")
      } }
    end

    product = Product.find_by!(slug: "plashch-test")
    assert_redirected_to admin_product_path(product)
    assert product.image.attached?

    follow_redirect!
    assert_select "h1", "Плащ «Тест»"
  end

  test "create re-renders the form when the category is a section" do
    sign_in_as users(:admin)

    assert_no_difference "Product.count" do
      post admin_products_path, params: { product: {
        name: "Плащ «Тест»",
        category_id: categories(:men).id,
        price: "9990"
      } }
    end

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /Товар можно добавить только в подкатегорию/
  end

  test "create rejects an unsupported image type" do
    sign_in_as users(:admin)

    assert_no_difference "Product.count" do
      post admin_products_path, params: { product: {
        name: "Плащ «Тест»",
        category_id: categories(:men_jackets).id,
        price: "9990",
        image: fixture_file_upload("product.txt", "text/plain")
      } }
    end

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /Допустимы только файлы JPEG, PNG или WebP/
  end

  test "show displays the product" do
    sign_in_as users(:admin)

    get admin_product_path(products(:men_jacket))

    assert_response :success
    assert_select "h1", "Куртка «Арден»"
  end

  test "edit renders the form with the current values" do
    sign_in_as users(:admin)

    get edit_admin_product_path(products(:men_jacket))

    assert_response :success
    assert_select "input[name='product[name]'][value=?]", "Куртка «Арден»"
    assert_select "input[name='product[price]'][value=?]", "12990.0"
  end

  test "update changes the product" do
    sign_in_as users(:admin)

    patch admin_product_path(products(:men_jacket)), params: { product: { price: "13990" } }

    assert_redirected_to admin_product_path(products(:men_jacket))
    assert_equal 13990, products(:men_jacket).reload.price.to_i
  end

  test "update hides a product by clearing the active flag" do
    sign_in_as users(:admin)

    patch admin_product_path(products(:men_jacket)), params: { product: { active: "0" } }

    assert_not products(:men_jacket).reload.active?
  end

  test "update re-renders the form on invalid data" do
    sign_in_as users(:admin)

    patch admin_product_path(products(:men_jacket)), params: { product: { name: "" } }

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /Название не может быть пустым/
  end

  test "destroy removes a product without orders" do
    sign_in_as users(:admin)

    assert_difference "Product.count", -1 do
      delete admin_product_path(products(:women_jacket))
    end

    assert_redirected_to admin_products_path
  end
end
