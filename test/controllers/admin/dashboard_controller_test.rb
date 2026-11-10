require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "guest is asked to sign in" do
    get admin_root_path

    assert_redirected_to new_session_path
  end

  test "customer is denied access" do
    sign_in_as users(:customer)

    get admin_root_path

    assert_redirected_to root_path

    follow_redirect!
    assert_select "#flash", text: /Доступ запрещён/
  end

  test "admin sees the dashboard" do
    sign_in_as users(:admin)

    get admin_root_path

    assert_response :success
    assert_select "h1", "Админ-панель"
    assert_select "main", text: /Добро пожаловать в админ-панель/
  end
end
