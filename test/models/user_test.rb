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

  test "defaults to the customer role" do
    user = build_user

    assert user.customer?
    assert_equal "customer", user.role
  end

  test "can be an admin" do
    user = build_user(role: :admin)

    assert user.admin?
    assert_equal "admin", user.role
  end

  test "full_name joins first and last name" do
    assert_equal "Иван Петров", users(:customer).full_name
  end

  test "authenticates with the right password only" do
    assert_equal users(:customer), User.authenticate_by(email_address: "IVAN@example.com", password: "password123")
    assert_nil User.authenticate_by(email_address: "ivan@example.com", password: "wrong-password")
  end

  test "favorite? looks at the user's own favourites" do
    user = users(:customer)

    assert user.favorite?(products(:men_jacket))
    assert_not user.favorite?(products(:women_jacket))
    assert_not users(:other_customer).favorite?(products(:men_jacket))
  end

  test "toggle_favorite! adds and removes a product" do
    user = users(:other_customer)
    product = products(:men_jacket)

    assert_difference -> { user.favorites.count }, 1 do
      assert user.toggle_favorite!(product)
    end
    assert user.favorite?(product)

    assert_difference -> { user.favorites.count }, -1 do
      assert_not user.toggle_favorite!(product)
    end
    assert_not user.favorite?(product)
  end

  test "toggle_favorite! keeps one row per product" do
    user = users(:other_customer)
    product = products(:men_jacket)

    user.toggle_favorite!(product)
    user.toggle_favorite!(product)
    user.toggle_favorite!(product)

    assert_equal 1, user.favorites.where(product: product).count
  end
end
