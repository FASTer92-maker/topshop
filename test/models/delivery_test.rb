require "test_helper"

class DeliveryTest < ActiveSupport::TestCase
  test "delivery costs 400 below the free threshold" do
    assert_equal 400, Delivery.price_for(0)
    assert_equal 400, Delivery.price_for(9_999)
  end

  test "delivery is free from the threshold" do
    assert_equal 0, Delivery.price_for(10_000)
    assert_equal 0, Delivery.price_for(15_000)
  end

  test "amount_to_free counts up to the threshold" do
    assert_equal 10_000, Delivery.amount_to_free(0)
    assert_equal 1, Delivery.amount_to_free(9_999)
  end

  test "amount_to_free is zero from the threshold" do
    assert_equal 0, Delivery.amount_to_free(10_000)
    assert_equal 0, Delivery.amount_to_free(15_000)
  end
end
