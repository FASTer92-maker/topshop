class ProductsController < ApplicationController
  include CatalogFilters

  allow_unauthenticated_access

  def index
    @pagy, @products = pagy(:offset, catalog_products)
  end

  private
    def catalog_products
      Product.active
             .filter_by(filter_params)
             .includes(:variants, category: :parent)
             .with_attached_image
    end
end
