require "test_helper"

class Admin::CategoriesControllerTest < ActionDispatch::IntegrationTest
  test "guest is asked to sign in" do
    get admin_categories_path

    assert_redirected_to new_session_path
  end

  test "customer is denied access" do
    sign_in_as users(:customer)

    get admin_categories_path

    assert_redirected_to root_path
  end

  test "index lists sections and their subcategories" do
    sign_in_as users(:admin)

    get admin_categories_path

    assert_response :success
    assert_select "h1", "Категории"
    assert_select "a[href=?]", new_admin_category_path, text: "Добавить категорию"
    assert_select "p", text: "Мужское"
    assert_select "p", text: "Куртки"
  end

  test "new renders the form" do
    sign_in_as users(:admin)

    get new_admin_category_path

    assert_response :success
    assert_select "h1", "Новая категория"
    assert_select "select[name='category[parent_id]']"
    assert_select "input[name='category[name]']"
  end

  test "create adds a subcategory with a generated slug" do
    sign_in_as users(:admin)

    assert_difference "Category.count", 1 do
      post admin_categories_path, params: { category: { parent_id: categories(:men).id, name: "Пуховики" } }
    end

    assert_redirected_to admin_categories_path
    assert_equal "muzhskoe-pukhoviki", Category.find_by!(name: "Пуховики").slug
  end

  test "create re-renders the form on invalid data" do
    sign_in_as users(:admin)

    assert_no_difference "Category.count" do
      post admin_categories_path, params: { category: { parent_id: categories(:men_jackets).id, name: "Пуховики" } }
    end

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /Родителем подкатегории может быть только раздел/
  end

  test "edit renders the form with the current values" do
    sign_in_as users(:admin)

    get edit_admin_category_path(categories(:men_jackets))

    assert_response :success
    assert_select "h1", "Изменить категорию"
    assert_select "input[name='category[name]'][value=?]", "Куртки"
  end

  test "update changes the category" do
    sign_in_as users(:admin)

    patch admin_category_path(categories(:men_jackets)), params: { category: { name: "Ветровки" } }

    assert_redirected_to admin_categories_path
    assert_equal "Ветровки", categories(:men_jackets).reload.name
  end

  test "update re-renders the form on invalid data" do
    sign_in_as users(:admin)

    patch admin_category_path(categories(:men_jackets)), params: { category: { name: "" } }

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /Название не может быть пустым/
  end

  test "show redirects to edit" do
    sign_in_as users(:admin)

    get admin_category_path(categories(:men))

    assert_redirected_to edit_admin_category_path(categories(:men))
  end

  test "destroy removes a subcategory" do
    sign_in_as users(:admin)

    assert_difference "Category.count", -1 do
      delete admin_category_path(categories(:women_skirts))
    end

    assert_redirected_to admin_categories_path
  end

  test "destroy keeps a subcategory that still has products" do
    sign_in_as users(:admin)

    assert_no_difference "Category.count" do
      delete admin_category_path(categories(:women_jackets))
    end

    assert_redirected_to admin_categories_path
    follow_redirect!
    assert_select "#flash", text: /зависимост/
  end

  test "destroy keeps a section that still has subcategories" do
    sign_in_as users(:admin)

    assert_no_difference "Category.count" do
      delete admin_category_path(categories(:men))
    end

    assert_redirected_to admin_categories_path
    follow_redirect!
    assert_select "#flash", text: /зависимост/
  end
end
