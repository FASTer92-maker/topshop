module FavoritesHelper
  # Product ids kept by the current user. Loaded once per request so a grid of
  # cards does not run one query per heart.
  def favorite_product_ids
    @favorite_product_ids ||= authenticated? ? Current.user.favorites.pluck(:product_id).to_set : Set.new
  end

  def favorite_for(product)
    favorite_product_ids.include?(product.id)
  end
end
