module Admin
  class VariantsController < BaseController
    before_action :set_product
    before_action :set_variant, only: %i[ edit update destroy ]

    # Variants are created and edited inline on the product page.
    def new
      redirect_to admin_product_path(@product)
    end

    def edit
      redirect_to admin_product_path(@product)
    end

    def create
      @variant = @product.variants.new(variant_params)

      if @variant.save
        respond_to do |format|
          format.turbo_stream { flash.now[:notice] = t(".success") }
          format.html { redirect_to admin_product_path(@product), notice: t(".success") }
        end
      else
        respond_to do |format|
          format.turbo_stream { render :create, status: :unprocessable_content }
          format.html { redirect_to admin_product_path(@product), alert: @variant.errors.full_messages.to_sentence }
        end
      end
    end

    def update
      if @variant.update(variant_params)
        respond_to do |format|
          format.turbo_stream { flash.now[:notice] = t(".success") }
          format.html { redirect_to admin_product_path(@product), notice: t(".success") }
        end
      else
        respond_to do |format|
          format.turbo_stream { render :update, status: :unprocessable_content }
          format.html { redirect_to admin_product_path(@product), alert: @variant.errors.full_messages.to_sentence }
        end
      end
    end

    def destroy
      if @variant.destroy
        respond_to do |format|
          format.turbo_stream { flash.now[:notice] = t(".success") }
          format.html { redirect_to admin_product_path(@product), notice: t(".success"), status: :see_other }
        end
      else
        redirect_to admin_product_path(@product), alert: @variant.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private
      def set_product
        @product = Product.find_by!(slug: params[:product_id])
      end

      def set_variant
        @variant = @product.variants.find(params[:id])
      end

      def variant_params
        params.expect(variant: [ :size, :color, :stock, :sku ])
      end
  end
end
