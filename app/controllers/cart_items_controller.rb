class CartItemsController < ApplicationController
  # Adds the chosen variant to the current user's cart. The product page sends
  # variant_id, so a request without it means the size was not picked.
  def create
    variant = Variant.find_by(id: params[:variant_id])

    return respond_with_error(t(".choose_size")) if variant.nil?

    item = Current.user.cart!.add_variant(variant, quantity)

    if item.errors.empty?
      respond_with_added(item)
    else
      respond_with_error(item.errors.messages_for(:quantity).to_sentence.presence || t(".unavailable"))
    end
  end

  private
    def quantity
      value = params[:quantity].presence

      value ? value.to_i : 1
    end

    def respond_with_added(item)
      @cart = item.cart

      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = t(".success")
          render :create
        end
        # Stage 13 opens the cart page here; until it exists the user stays put.
        format.html { redirect_back fallback_location: root_path, notice: t(".success") }
      end
    end

    def respond_with_error(message)
      @cart = Current.user.cart

      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = message
          render :error, status: :unprocessable_content
        end
        format.html { redirect_back fallback_location: root_path, alert: message }
      end
    end
end
