module CatalogHelper
  # Counter above the grid, mentioning the query when there is one.
  def catalog_found_text(count)
    if params[:q].present?
      t("catalog.found_search", count: count, query: params[:q])
    else
      t("catalog.found", count: count)
    end
  end

  # Colours that can actually be bought right now, for the filter select.
  def catalog_colors
    @catalog_colors ||= Variant.in_stock
                               .where(product_id: Product.active.select(:id))
                               .distinct
                               .order(:color)
                               .pluck(:color)
  end

  def catalog_filters_active?
    params.slice(:q, :size, :color, :price_from, :price_to, :in_stock).values.any?(&:present?)
  end

  def catalog_sort_options
    [
      [ t("catalog.filters.sort_default"), "default" ],
      [ t("catalog.filters.sort_price_asc"), "price_asc" ],
      [ t("catalog.filters.sort_price_desc"), "price_desc" ]
    ]
  end

  def catalog_label_class
    "block text-[13px] font-medium text-muted"
  end

  def catalog_control_class
    "mt-1 w-full rounded-md border border-line bg-white px-3 py-2 text-sm text-ink outline-none transition-colors focus:border-ink"
  end
end
