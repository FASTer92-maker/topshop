module Admin
  module OrdersHelper
    # Filled pill for the active status tab, outlined pills for the rest.
    def admin_order_tab_class(status)
      base = "rounded-full border px-3 py-1.5 text-sm font-medium transition-colors"

      if params[:status].presence == status
        "#{base} border-ink bg-ink text-white"
      else
        "#{base} border-line bg-white hover:border-ink"
      end
    end
  end
end
