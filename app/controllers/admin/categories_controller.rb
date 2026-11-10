module Admin
  class CategoriesController < BaseController
    before_action :set_category, only: %i[ show edit update destroy ]

    def index
      @sections = Category.sections.ordered.includes(:subcategories)
    end

    def show
      redirect_to edit_admin_category_path(@category)
    end

    def new
      @category = Category.new
      @sections = Category.sections.ordered
    end

    def create
      @category = Category.new(category_params)

      if @category.save
        redirect_to admin_categories_path, notice: t(".success")
      else
        @sections = Category.sections.ordered
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @sections = Category.sections.ordered
    end

    def update
      if @category.update(category_params)
        redirect_to admin_categories_path, notice: t(".success")
      else
        @sections = Category.sections.ordered
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @category.destroy
        redirect_to admin_categories_path, notice: t(".success"), status: :see_other
      else
        redirect_to admin_categories_path, alert: @category.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private
      def set_category
        @category = Category.find_by!(slug: params[:id])
      end

      def category_params
        params.expect(category: [ :parent_id, :name, :description, :position ])
      end
  end
end
