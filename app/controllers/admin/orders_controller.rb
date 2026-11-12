module Admin
  class OrdersController < BaseController
    before_action :set_order, only: %i[ show update ]

    def index
      orders = Order.recent.includes(:user, :order_items)
      orders = orders.where(status: params[:status]) if Order.statuses.key?(params[:status])

      @pagy, @orders = pagy(:offset, orders)
      @status_counts = Order.group(:status).count
    end

    def show
    end

    def update
      @order.transition_to!(params.expect(:status))

      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = transition_notice }
        format.html { redirect_to admin_order_path(@order), notice: transition_notice }
      end
    rescue Order::InvalidTransitionError => error
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = error.message
          render :update, status: :unprocessable_content
        end
        format.html { redirect_to admin_order_path(@order), alert: error.message }
      end
    end

    private
      def set_order
        @order = Order.find(params[:id])
      end

      def transition_notice
        t(".success", status: t("orders.statuses.#{@order.status}"))
      end
  end
end
