require "test_helper"

class SubscriberTest < ActiveSupport::TestCase
  test "normalizes the email" do
    subscriber = Subscriber.create!(email: "  News@Example.COM ")

    assert_equal "news@example.com", subscriber.email
  end

  test "requires a valid email" do
    subscriber = Subscriber.new(email: "not-an-email")

    assert_not subscriber.valid?
    assert_includes subscriber.errors[:email], "имеет неверное значение"
  end

  test "requires a unique email" do
    subscriber = Subscriber.new(email: subscribers(:existing).email.upcase)

    assert_not subscriber.valid?
    assert_includes subscriber.errors[:email], "уже используется"
  end

  test "subscribe creates a normalized subscriber" do
    assert_difference -> { Subscriber.count }, 1 do
      subscriber = Subscriber.subscribe(" New@Example.com ")

      assert subscriber.persisted?
      assert_equal "new@example.com", subscriber.email
    end
  end

  test "subscribe returns the existing subscriber without a duplicate" do
    assert_no_difference -> { Subscriber.count } do
      subscriber = Subscriber.subscribe(" READER@Example.com ")

      assert_equal subscribers(:existing), subscriber
      assert_predicate subscriber, :persisted?
    end
  end

  test "subscribe returns an unsaved subscriber for an invalid email" do
    assert_no_difference -> { Subscriber.count } do
      subscriber = Subscriber.subscribe("broken")

      assert_not subscriber.persisted?
      assert_includes subscriber.errors[:email], "имеет неверное значение"
    end
  end
end
