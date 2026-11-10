class CategoriesController < ApplicationController
  include CatalogFilters

  allow_unauthenticated_access

  def show
    @category = Category.find_by!(slug: params[:slug])
    @subcategories = @category.subcategories.ordered if @category.section?

    @pagy, @products = pagy(:offset, catalog_products)
  end

  private
    def catalog_products
      Product.active
             .in_category(@category)
             .filter_by(filter_params)
             .includes(:variants, category: :parent)
             .with_attached_image
    end
end
