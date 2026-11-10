class HomeController < ApplicationController
  allow_unauthenticated_access

  NEW_ARRIVALS_LIMIT = 8

  def index
    @new_arrivals = Product.active
                           .newest
                           .includes(:variants, category: :parent)
                           .with_attached_image
                           .limit(NEW_ARRIVALS_LIMIT)

    @banners = Category.sections.ordered.first(2)
  end
end
