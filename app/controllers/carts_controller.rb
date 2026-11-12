class CartsController < ApplicationController
  def show
    @cart = Current.user.cart!
    @cart_items = @cart.cart_items.for_cart_page
  end
end
