module OrdersHelper
  # The happy path of an order from ERD §3, without cancellation.
  STATUS_FLOW = %w[pending paid assembled shipped delivered].freeze

  # Badge colours from ERD §3: grey, black, tobacco, green and red.
  STATUS_BADGE_CLASSES = {
    "pending" => "bg-surface text-ink",
    "paid" => "bg-ink text-white",
    "assembled" => "bg-accent text-white",
    "shipped" => "bg-accent text-white",
    "delivered" => "bg-success text-white",
    "cancelled" => "bg-danger text-white"
  }.freeze

  DEFAULT_BADGE_CLASSES = "bg-surface text-ink".freeze

  # Returns the Russian status name and the Tailwind classes for its colour.
  # Accepts an order or a status string/symbol.
  def status_badge(order_or_status)
    status = order_or_status.respond_to?(:status) ? order_or_status.status : order_or_status.to_s

    {
      label: t("orders.statuses.#{status}"),
      classes: STATUS_BADGE_CLASSES.fetch(status, DEFAULT_BADGE_CLASSES)
    }
  end

  # True for the current status and every status before it on the progress bar.
  def status_step_reached?(order, step)
    current_index = STATUS_FLOW.index(order.status)
    step_index = STATUS_FLOW.index(step)

    current_index.present? && step_index.present? && step_index <= current_index
  end

  def status_step_current?(order, step)
    order.status == step
  end
end
