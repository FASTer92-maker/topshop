module Admin
  class ProductsController < BaseController
    before_action :set_product, only: %i[ show edit update destroy ]
    before_action :set_sections, only: %i[ new create edit update ]

    def index
      @products = Product.admin_search(params[:q])
                        .includes(:category, :variants)
                        .with_attached_image
                        .order(created_at: :desc)
    end

    def show
      @variant = Variant.new
    end

    def new
      @product = Product.new
    end

    def create
      @product = Product.new(product_params)

      if @product.save
        redirect_to admin_product_path(@product), notice: t(".success")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @product.update(product_params)
        redirect_to admin_product_path(@product), notice: t(".success")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @product.destroy
        redirect_to admin_products_path, notice: t(".success"), status: :see_other
      else
        redirect_to admin_product_path(@product), alert: @product.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private
      def set_product
        @product = Product.find_by!(slug: params[:id])
      end

      def set_sections
        @sections = Category.sections.ordered.includes(:subcategories)
      end

      def product_params
        params.expect(product: [ :category_id, :name, :description, :price, :active, :image ])
      end
  end
end
