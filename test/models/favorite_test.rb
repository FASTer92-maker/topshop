require "test_helper"

class FavoriteTest < ActiveSupport::TestCase
  test "valid with a user and a product" do
    assert Favorite.new(user: users(:other_customer), product: products(:men_jacket)).valid?
  end

  test "requires a user and a product" do
    favorite = Favorite.new

    assert_not favorite.valid?
    assert_includes favorite.errors[:user], "должно существовать"
    assert_includes favorite.errors[:product], "должно существовать"
  end

  test "one user cannot favourite the same product twice" do
    favorite = Favorite.new(user: users(:customer), product: products(:men_jacket))

    assert_not favorite.valid?
    assert favorite.errors.added?(:product_id, :taken, value: products(:men_jacket).id)
  end

  test "different users can favourite the same product" do
    assert Favorite.create!(user: users(:other_customer), product: products(:men_jacket))
  end

  test "is removed together with its product" do
    product = Product.create!(category: categories(:men_jackets), name: "Кепка", price: 1000, active: true)
    Favorite.create!(user: users(:customer), product: product)

    assert_difference -> { Favorite.count }, -1 do
      product.destroy!
    end
  end

  test "is removed together with its user" do
    user = User.create!(email_address: "favorite@example.com", first_name: "Ольга", last_name: "Смирнова",
                        password: "secret123", password_confirmation: "secret123")
    Favorite.create!(user: user, product: products(:men_jacket))

    assert_difference -> { Favorite.count }, -1 do
      user.destroy!
    end
  end
end
