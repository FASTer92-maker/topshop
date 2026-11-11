class ProductsController < ApplicationController
  include CatalogFilters

  allow_unauthenticated_access

  def index
    @pagy, @products = pagy(:offset, catalog_products)
  end

  # Only active products have a public page; hidden ones raise 404.
  def show
    @product = Product.active
                      .includes(:variants, category: :parent)
                      .with_attached_image
                      .find_by!(slug: params[:slug])

    @similar_products = similar_products
  end

  private
    def catalog_products
      Product.active
             .filter_by(filter_params)
             .includes(:variants, category: :parent)
             .with_attached_image
    end

    # Up to four other active products from the same subcategory.
    def similar_products
      Product.active
             .where(category_id: @product.category_id)
             .where.not(id: @product.id)
             .newest
             .includes(:variants)
             .with_attached_image
             .limit(4)
    end
end
