require "test_helper"

class OrdersHelperTest < ActionView::TestCase
  test "returns the Russian label and grey classes for a pending order" do
    badge = status_badge("pending")

    assert_equal "Новый", badge[:label]
    assert_equal "bg-surface text-ink", badge[:classes]
  end

  test "returns the Russian label and black classes for a paid order" do
    badge = status_badge(:paid)

    assert_equal "Оплачен", badge[:label]
    assert_equal "bg-ink text-white", badge[:classes]
  end

  test "uses the tobacco accent for assembled and shipped orders" do
    assert_equal "Собран", status_badge("assembled")[:label]
    assert_equal "bg-accent text-white", status_badge("assembled")[:classes]

    assert_equal "Отправлен", status_badge("shipped")[:label]
    assert_equal "bg-accent text-white", status_badge("shipped")[:classes]
  end

  test "uses green for a delivered order and red for a cancelled one" do
    assert_equal "Доставлен", status_badge("delivered")[:label]
    assert_equal "bg-success text-white", status_badge("delivered")[:classes]

    assert_equal "Отменён", status_badge("cancelled")[:label]
    assert_equal "bg-danger text-white", status_badge("cancelled")[:classes]
  end

  test "accepts an order record" do
    order = Order.new(status: :assembled)

    assert_equal "Собран", status_badge(order)[:label]
    assert_equal "bg-accent text-white", status_badge(order)[:classes]
  end

  test "marks the current step and every step before it as reached" do
    order = Order.new(status: :assembled)

    assert status_step_reached?(order, "pending")
    assert status_step_reached?(order, "paid")
    assert status_step_reached?(order, "assembled")
    assert_not status_step_reached?(order, "shipped")
    assert_not status_step_reached?(order, "delivered")

    assert status_step_current?(order, "assembled")
    assert_not status_step_current?(order, "paid")
  end

  test "a cancelled order has no reached steps" do
    order = Order.new(status: :cancelled)

    OrdersHelper::STATUS_FLOW.each do |step|
      assert_not status_step_reached?(order, step)
    end
  end
end
