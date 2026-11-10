class CategoriesController < ApplicationController
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
             .newest
             .includes(:variants, category: :parent)
             .with_attached_image
    end
end
