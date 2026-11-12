class OrdersController < ApplicationController
  def index
    @orders = Current.user.orders.recent.includes(:order_items)
  end

  # Only the current user's orders are visible: somebody else's id is a 404.
  def show
    @order = Current.user.orders.find(params[:id])
  end

  def new
    @cart = Current.user.cart!

    return redirect_to cart_path, alert: t(".empty_cart") if @cart.empty?
    return redirect_to cart_path, alert: t(".cart_not_ready") unless @cart.checkout_ready?

    @cart_items = @cart.cart_items.for_cart_page
    @order = Current.user.orders.build(full_name: Current.user.full_name)
  end

  def create
    cart = Current.user.cart!

    begin
      order = Order.place_from_cart!(cart, order_params)
    rescue Order::InsufficientStockError => error
      redirect_to cart_path, alert: error.message
    rescue Order::EmptyCartError
      redirect_to cart_path, alert: t(".empty_cart")
    rescue ActiveRecord::RecordInvalid => error
      render_checkout_form(error.record, cart)
    else
      redirect_to order_path(order), notice: t(".success")
    end
  end

  private
    def order_params
      params.require(:order).permit(:full_name, :phone, :address, :comment)
    end

    def render_checkout_form(order, cart)
      @order = order
      @cart = cart
      @cart_items = cart.cart_items.for_cart_page

      render :new, status: :unprocessable_content
    end
end
