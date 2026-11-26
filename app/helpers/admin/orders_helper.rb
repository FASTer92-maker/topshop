module Admin
  module OrdersHelper
    # Filled pill for the active status tab, outlined pills for the rest.
    def admin_order_tab_class(status)
      base = "inline-flex items-center border px-4 py-2 text-sm font-medium transition-colors duration-300"

      if params[:status].presence == status
        "#{base} border-ink bg-ink text-white"
      else
        "#{base} border-line bg-white text-muted hover:border-accent hover:text-ink"
      end
    end
  end
end
