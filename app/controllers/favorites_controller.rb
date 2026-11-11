class FavoritesController < ApplicationController
  def index
    @favorite_products = Current.user.favorite_products
                                 .includes(:variants, category: :parent)
                                 .with_attached_image
                                 .order("favorites.created_at DESC")
  end

  def create
    Current.user.favorites.find_or_create_by!(product: product)

    respond_with_toggle
  end

  # Only the current user's favourites are reachable here, so a foreign
  # product raises 404 instead of deleting somebody else's row.
  def destroy
    Current.user.favorites.find_by!(product: product).destroy!

    respond_with_toggle
  end

  private
    def product
      @product ||= Product.find_by!(slug: params[:product_slug])
    end

    def respond_with_toggle
      respond_to do |format|
        format.turbo_stream { render :toggle, locals: { product: product } }
        format.html { redirect_back fallback_location: favorites_path }
      end
    end
end
