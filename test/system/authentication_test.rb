require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "guest registers and lands on the home page signed in" do
    visit root_path
    click_on "Войти"
    click_on "Зарегистрироваться"

    fill_in "Email", with: "anna@example.com"
    fill_in "Имя", with: "Анна"
    fill_in "Фамилия", with: "Иванова"
    fill_in "Пароль", with: "secret123"
    fill_in "Подтверждение пароля", with: "secret123"
    click_on "Зарегистрироваться"

    assert_text "Добро пожаловать, Анна!"
    within("header") { assert_selector "summary", text: "Анна" }
  end

  test "registration shows validation errors" do
    visit new_registration_path

    fill_in "Email", with: "ivan@example.com"
    fill_in "Имя", with: "Иван"
    fill_in "Фамилия", with: "Петров"
    fill_in "Пароль", with: "secret123"
    fill_in "Подтверждение пароля", with: "different1"
    click_on "Зарегистрироваться"

    assert_text "Email уже используется"
    assert_text "Подтверждение пароля не совпадает со значением поля Пароль"
  end

  test "customer signs in and signs out" do
    visit new_session_path

    fill_in "Email", with: "ivan@example.com"
    fill_in "Пароль", with: "password123"
    click_on "Войти", class: "btn-primary"

    within("header") do
      find("summary", text: "Иван").click
      assert_text "Иван Петров"
      click_on "Выйти"
    end

    assert_text "Вы вышли из аккаунта."
    within("header") { assert_link "Войти" }
  end

  test "wrong password keeps the email and shows an error" do
    visit new_session_path

    fill_in "Email", with: "ivan@example.com"
    fill_in "Пароль", with: "wrong-password"
    click_on "Войти", class: "btn-primary"

    assert_text "Неверный email или пароль."
    assert_field "Email", with: "ivan@example.com"
  end
end
