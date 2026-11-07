require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:customer) }

  test "new renders the sign in form" do
    get new_session_path

    assert_response :success
    assert_select "h1", "Вход"
    assert_select "a[href=?]", new_registration_path
    assert_select "a[href=?]", new_password_path
  end

  test "create with valid credentials signs in and returns home" do
    post session_path, params: { email_address: "IVAN@example.com", password: "password123" }

    assert_redirected_to root_path
    assert cookies[:session_id].present?
  end

  test "create with invalid credentials re-renders the form" do
    post session_path, params: { email_address: @user.email_address, password: "wrong-password" }

    assert_response :unprocessable_content
    assert_nil cookies[:session_id]
    assert_select "#flash [role=alert] p", text: "Неверный email или пароль."
    assert_select "input[name=email_address][value=?]", @user.email_address
  end

  test "destroy signs out and returns home" do
    sign_in_as @user

    delete session_path

    assert_redirected_to root_path
    assert_empty cookies[:session_id]

    follow_redirect!
    assert_select "#flash", text: /Вы вышли из аккаунта/
    assert_select "header a[href=?]", new_session_path, text: "Войти"
  end

  test "destroy requires a session" do
    delete session_path

    assert_redirected_to new_session_path
  end
end
