require "application_system_test_case"

class SizeSelectionTest < ApplicationSystemTestCase
  test "guest is asked to pick a size before adding to the cart" do
    visit product_path(products(:men_jacket))

    click_on "В корзину"

    assert_text "Выберите размер"
  end

  test "picking a colour shows its sizes and the low stock hint" do
    visit product_path(products(:men_jacket))

    within("[data-size-color='Табачный']") { find("label", text: "M", exact_text: true).click }
    assert_text "Осталось 2 шт."

    find("label", text: "Чёрный", exact_text: true).click
    assert_no_text "Осталось 2 шт."

    within("[data-size-color='Чёрный']") do
      assert_selector "input[type=radio]", count: 2
      assert_selector "input[type=radio][disabled]", count: 1
    end
  end

  test "a size that is out of stock cannot be chosen" do
    visit product_path(products(:men_jacket))

    find("label", text: "Чёрный", exact_text: true).click
    within("[data-size-color='Чёрный']") { find("label", text: "M", exact_text: true).click }
    assert_no_text "Осталось"

    within("[data-size-color='Чёрный']") do
      find("label", text: "L", exact_text: true).click
    end

    assert_no_checked_field "L"
  end

  test "the only variant is selected automatically" do
    product = Product.create!(category: categories(:accessories_bags), name: "Ремень", price: 3000, active: true)
    variant = product.variants.create!(size: "ONE SIZE", color: "Чёрный", stock: 4, sku: "AC-BEL-CHE-OS")

    visit product_path(product)

    assert_checked_field "variant_#{variant.id}"

    click_on "В корзину"

    assert_no_text "Выберите размер"
  end

  test "guest opens the product page from the catalog" do
    visit products_path

    click_on "Куртка «Арден»"

    assert_selector "h1", text: /куртка «арден»/i
    assert_button "В корзину", disabled: false
  end
end
