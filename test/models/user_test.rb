require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(**attributes)
    User.new(email_address: "new@example.com", first_name: "Анна", last_name: "Иванова",
             password: "secret123", password_confirmation: "secret123", **attributes)
  end

  test "valid with all attributes" do
    assert build_user.valid?
  end

  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "squishes names" do
    user = build_user(first_name: "  Анна  ", last_name: " Иванова-  Петрова ")

    assert_equal "Анна", user.first_name
    assert_equal "Иванова- Петрова", user.last_name
  end

  test "requires email, first name and last name" do
    user = build_user(email_address: "", first_name: "", last_name: "")

    assert_not user.valid?
    assert_includes user.errors[:email_address], "не может быть пустым"
    assert_includes user.errors[:first_name], "не может быть пустым"
    assert_includes user.errors[:last_name], "не может быть пустым"
  end

  test "rejects malformed email" do
    user = build_user(email_address: "not-an-email")

    assert_not user.valid?
    assert user.errors.added?(:email_address, :invalid, value: "not-an-email")
  end

  test "email must be unique regardless of case" do
    user = build_user(email_address: users(:customer).email_address.upcase)

    assert_not user.valid?
    assert_equal [ "Email уже используется" ], user.errors.full_messages_for(:email_address)
  end

  test "limits name length to 50 characters" do
    user = build_user(first_name: "а" * 51)

    assert_not user.valid?
    assert user.errors.of_kind?(:first_name, :too_long)
  end

  test "password must be at least 8 characters" do
    user = build_user(password: "short1", password_confirmation: "short1")

    assert_not user.valid?
    assert_equal [ "Пароль слишком короткий (не менее 8 символов)" ], user.errors.full_messages_for(:password)
  end

  test "password must match confirmation" do
    user = build_user(password_confirmation: "different1")

    assert_not user.valid?
    assert user.errors.of_kind?(:password_confirmation, :confirmation)
  end

  test "existing user can be updated without changing the password" do
    user = users(:customer)

    assert user.update(first_name: "Пётр")
  end

  test "full_name joins first and last name" do
    assert_equal "Иван Петров", users(:customer).full_name
  end

  test "authenticates with the right password only" do
    assert_equal users(:customer), User.authenticate_by(email_address: "IVAN@example.com", password: "password123")
    assert_nil User.authenticate_by(email_address: "ivan@example.com", password: "wrong-password")
  end
end
