require "application_system_test_case"

class AdminVariantsTest < ApplicationSystemTestCase
  test "admin adds a variant and updates its stock" do
    sign_in_as_admin
    product = products(:men_jacket)

    visit admin_product_path(product)

    within "#new_variant_form" do
      select "XL", from: "Размер"
      fill_in "Цвет", with: "Белый"
      fill_in "Артикул", with: "MJ-ARD-BEL-XL"
      fill_in "Остаток", with: "4"
      click_on "Добавить вариант"
    end

    assert_text "Вариант добавлен."
    assert_text "XL · Белый"

    variant = product.variants.find_by!(sku: "MJ-ARD-BEL-XL")

    within "#variant_#{variant.id}" do
      find("summary", text: "Изменить").click
      fill_in "Остаток", with: "1"
      click_on "Сохранить"
    end

    assert_text "Вариант обновлён."
    assert_equal 1, variant.reload.stock
  end

  test "admin deletes a variant" do
    sign_in_as_admin
    product = products(:women_jacket)
    variant = variants(:women_jacket_s_black)

    visit admin_product_path(product)

    within "#variant_#{variant.id}" do
      accept_confirm { click_on "Удалить" }
    end

    assert_text "Вариант удалён."
    assert_no_text "S · Чёрный"
  end

  private
    def sign_in_as_admin
      visit new_session_path
      fill_in "Email", with: "admin@example.com"
      fill_in "Пароль", with: "password123"
      click_on "Войти", class: "btn-primary"
      within("header") { assert_selector "summary", text: "Админ" }
    end
end
