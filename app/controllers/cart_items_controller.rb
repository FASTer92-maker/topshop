class CartItemsController < ApplicationController
  # The product form sends variant_id, so a request without it means no size
  # was picked. Adding a variant always opens the cart page.
  def create
    variant = Variant.find_by(id: params[:variant_id])

    return respond_with_error(t(".choose_size")) if variant.nil?

    item = Current.user.cart!.add_variant(variant, quantity)

    if item.errors.empty?
      redirect_to cart_path, notice: t(".success")
    else
      respond_with_error(item.errors.messages_for(:quantity).to_sentence.presence || t(".unavailable"))
    end
  end

  def update
    item = cart_item
    new_quantity = parsed_quantity

    return respond_with_error(t(".invalid_quantity")) if new_quantity.nil?

    if new_quantity.zero?
      item.destroy!
      return respond_with_change(notice: t("cart_items.destroy.removed"))
    end

    return respond_with_change if item.update(quantity: new_quantity)

    respond_with_error(item.errors.messages_for(:quantity).to_sentence.presence || t(".unavailable"))
  end

  def destroy
    cart_item.destroy!

    respond_with_change(notice: t(".removed"))
  end

  private
    # Scoped to the current user's cart, so somebody else's item is a 404.
    def cart_item
      Current.user.cart!.cart_items.find(params[:id])
    end

    def quantity
      value = params[:quantity].presence

      value ? value.to_i : 1
    end

    def parsed_quantity
      value = params[:quantity].to_s

      value.to_i if value.match?(/\A\d+\z/)
    end

    def respond_with_change(notice: nil)
      @cart = Current.user.cart!
      @cart_items = @cart.cart_items.for_cart_page

      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = notice if notice
          render :change
        end
        format.html { redirect_to cart_path, notice: notice }
      end
    end

    def respond_with_error(message)
      @cart = Current.user.cart

      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = message
          render :error, status: :unprocessable_content
        end
        format.html { redirect_back fallback_location: cart_path, alert: message }
      end
    end
end
