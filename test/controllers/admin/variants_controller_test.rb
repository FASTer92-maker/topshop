require "test_helper"

class Admin::VariantsControllerTest < ActionDispatch::IntegrationTest
  test "guest is asked to sign in" do
    get admin_product_path(products(:men_jacket))

    assert_redirected_to new_session_path
  end

  test "customer is denied access" do
    sign_in_as users(:customer)

    get admin_product_path(products(:men_jacket))

    assert_redirected_to root_path
  end

  test "new redirects to the product page" do
    sign_in_as users(:admin)

    get new_admin_product_variant_path(products(:men_jacket))

    assert_redirected_to admin_product_path(products(:men_jacket))
  end

  test "edit redirects to the product page" do
    sign_in_as users(:admin)

    get edit_admin_product_variant_path(products(:men_jacket), variants(:men_jacket_m_black))

    assert_redirected_to admin_product_path(products(:men_jacket))
  end

  test "create adds a variant and answers with a turbo stream" do
    sign_in_as users(:admin)

    assert_difference "Variant.count", 1 do
      post admin_product_variants_path(products(:men_jacket)),
           params: { variant: { size: "XL", color: "Белый", stock: "3", sku: "mj-ard-bel-xl" } },
           as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match "variants_list", response.body
    assert_match "MJ-ARD-BEL-XL", response.body
  end

  test "create re-renders the form with errors on invalid data" do
    sign_in_as users(:admin)

    assert_no_difference "Variant.count" do
      post admin_product_variants_path(products(:men_jacket)),
           params: { variant: { size: "XL", color: "Белый", stock: "3", sku: variants(:men_jacket_m_black).sku } },
           as: :turbo_stream
    end

    assert_response :unprocessable_content
    assert_match "Артикул уже используется", response.body
  end

  test "update changes a variant and replaces its row" do
    sign_in_as users(:admin)
    variant = variants(:men_jacket_m_black)

    patch admin_product_variant_path(products(:men_jacket), variant),
          params: { variant: { stock: "1" } },
          as: :turbo_stream

    assert_response :success
    assert_equal 1, variant.reload.stock
    assert_match "variant_#{variant.id}", response.body
  end

  test "update returns errors when the stock is invalid" do
    sign_in_as users(:admin)
    variant = variants(:men_jacket_m_black)

    patch admin_product_variant_path(products(:men_jacket), variant),
          params: { variant: { stock: "-1" } },
          as: :turbo_stream

    assert_response :unprocessable_content
    assert_match "Остаток", response.body
  end

  test "destroy removes a variant" do
    sign_in_as users(:admin)

    assert_difference "Variant.count", -1 do
      delete admin_product_variant_path(products(:men_jacket), variants(:men_jacket_m_tabacco)),
             as: :turbo_stream
    end

    assert_response :success
    assert_match "action=\"remove\"", response.body
    assert_match "variant_#{variants(:men_jacket_m_tabacco).id}", response.body
  end

  test "a variant of another product is not found" do
    sign_in_as users(:admin)

    patch admin_product_variant_path(products(:women_jacket), variants(:men_jacket_m_black)),
          params: { variant: { stock: "1" } }

    assert_response :not_found
  end
end
