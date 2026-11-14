module Admin
  class DashboardController < BaseController
    def index
      @status_counts = Order.group(:status).count
      @revenue = Order.revenue
      @subscribers_count = Subscriber.count
      @low_stock_variants = Variant.low_stock.includes(:product).order(:stock, :product_id)
      @recent_orders = Order.recent.includes(:user).limit(5)
    end
  end
end
