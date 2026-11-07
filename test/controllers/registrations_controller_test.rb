require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  def valid_params(**overrides)
    { user: { email_address: "anna@example.com", first_name: "Анна", last_name: "Иванова",
              password: "secret123", password_confirmation: "secret123" }.merge(overrides) }
  end

  test "new renders the registration form" do
    get new_registration_path

    assert_response :success
    assert_select "h1", "Регистрация"
    assert_select "form[action=?]", registration_path do
      assert_select "input[name='user[email_address]']"
      assert_select "input[name='user[first_name]']"
      assert_select "input[name='user[last_name]']"
      assert_select "input[name='user[password]']"
      assert_select "input[name='user[password_confirmation]']"
    end
  end

  test "create registers the user, signs them in and greets them" do
    assert_difference [ "User.count", "Session.count" ], 1 do
      post registration_path, params: valid_params
    end

    assert_redirected_to root_path
    assert cookies[:session_id].present?

    follow_redirect!
    assert_select "#flash", text: /Добро пожаловать, Анна!/
    assert_select "#account_menu", text: /Анна/
  end

  test "create with invalid data re-renders the form with errors" do
    assert_no_difference "User.count" do
      post registration_path, params: valid_params(first_name: "", password_confirmation: "mismatch1")
    end

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /Имя не может быть пустым/
    assert_select "[role=alert]", text: /Подтверждение пароля не совпадает/
    assert_nil cookies[:session_id]
  end

  test "create rejects an email that is already taken" do
    assert_no_difference "User.count" do
      post registration_path, params: valid_params(email_address: " IVAN@example.com ")
    end

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /Email уже используется/
  end

  test "create ignores attributes that are not allowed" do
    post registration_path, params: valid_params(role: "admin", id: 999_999)

    user = User.find_by!(email_address: "anna@example.com")
    assert_not_equal 999_999, user.id
  end

  test "signed in users are sent to the home page" do
    sign_in_as users(:customer)

    get new_registration_path
    assert_redirected_to root_path

    assert_no_difference "User.count" do
      post registration_path, params: valid_params
    end
    assert_redirected_to root_path
  end
end
