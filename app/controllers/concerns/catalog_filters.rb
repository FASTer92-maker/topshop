# Filter parameters shared by the storefront catalog controllers.
# Everything is whitelisted here; `Product.filter_by` ignores invalid values.
module CatalogFilters
  extend ActiveSupport::Concern

  FILTER_KEYS = %i[ q size color price_from price_to in_stock sort ].freeze

  private
    def filter_params
      params.permit(*FILTER_KEYS).to_h
    end
end
