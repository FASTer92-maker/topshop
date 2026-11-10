class Product < ApplicationRecord
  SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  belongs_to :category
  has_many :variants, -> { by_size }, dependent: :destroy, inverse_of: :product
  has_many :order_items, through: :variants
  has_one_attached :image

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, length: { maximum: 150 }
  validates :slug, presence: true, uniqueness: true, format: { with: SLUG_FORMAT }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates_with ImageValidator, attribute: :image
  validate :category_must_be_a_subcategory

  before_validation :generate_slug, if: -> { slug.blank? }
  before_destroy :ensure_not_ordered, prepend: true

  # Sort keys exposed to the catalog filter bar. Anything else falls back to
  # the default order, so the parameter cannot inject SQL.
  SORT_ORDERS = {
    "default" => { created_at: :desc, id: :desc },
    "price_asc" => { price: :asc, id: :asc },
    "price_desc" => { price: :desc, id: :desc }
  }.freeze
  DEFAULT_SORT = "default"

  scope :active, -> { where(active: true) }
  scope :newest, -> { order(created_at: :desc) }
  scope :in_stock, -> { where(id: Variant.in_stock.select(:product_id)) }
  # A section includes the products of all its subcategories.
  scope :in_category, ->(category) { where(category_id: category.self_and_subcategory_ids) }

  # Storefront search over the name and the description, case-insensitive.
  scope :search, ->(query) do
    query = query.to_s.strip

    if query.blank?
      all
    else
      pattern = "%#{sanitize_sql_like(query)}%"
      where("products.name ILIKE :pattern OR products.description ILIKE :pattern", pattern: pattern)
    end
  end

  scope :price_from, ->(value) do
    price = decimal_price(value)
    price ? where(price: price..) : all
  end

  scope :price_to, ->(value) do
    price = decimal_price(value)
    price ? where(price: ..price) : all
  end

  # Size and colour filters match only variants that are actually in stock and
  # use a subquery, so a product never appears twice.
  scope :with_size, ->(size) do
    size = size.to_s.strip.upcase

    if Variant::SIZES.include?(size)
      where(id: Variant.in_stock.where(size: size).select(:product_id))
    else
      all
    end
  end

  scope :with_color, ->(color) do
    color = color.to_s.strip

    if color.blank?
      all
    else
      where(id: Variant.in_stock.where("variants.color ILIKE ?", sanitize_sql_like(color)).select(:product_id))
    end
  end

  scope :sorted_by, ->(key) { order(SORT_ORDERS.fetch(key.to_s, SORT_ORDERS[DEFAULT_SORT])) }

  # Everything the catalog filter bar sends at once. Unknown or malformed
  # values are ignored instead of raising.
  scope :filter_by, ->(filters) do
    filters = filters.to_h.symbolize_keys

    products = search(filters[:q])
    products = products.price_from(filters[:price_from])
    products = products.price_to(filters[:price_to])
    products = products.with_size(filters[:size])
    products = products.with_color(filters[:color])
    products = products.in_stock if boolean_value(filters[:in_stock])
    products.sorted_by(filters[:sort])
  end

  # Admin list search: product name or the SKU of any of its variants.
  scope :admin_search, ->(query) do
    query = query.to_s.strip

    if query.blank?
      all
    else
      pattern = "%#{sanitize_sql_like(query)}%"
      where(
        "products.name ILIKE :pattern OR products.slug ILIKE :pattern OR EXISTS (" \
        "SELECT 1 FROM variants WHERE variants.product_id = products.id AND variants.sku ILIKE :pattern)",
        pattern: pattern
      )
    end
  end

  def to_param
    slug
  end

  # "12 990" and "12,5" are valid prices, anything else is ignored.
  def self.decimal_price(value)
    return nil if value.blank?

    normalized = value.to_s.gsub(/[\s\u00A0\u202F]/, "").tr(",", ".")
    decimal = BigDecimal(normalized, exception: false)
    decimal if decimal && !decimal.negative?
  end

  # "1", "true" and "on" mean the checkbox is ticked; "0" and junk mean it is not.
  def self.boolean_value(value)
    ActiveModel::Type::Boolean.new.cast(value) == true
  end

  def in_stock?
    variants.in_stock.exists?
  end

  def available_sizes
    variants.in_stock.pluck(:size).uniq
  end

  def colors
    variants.reorder(:color).distinct.pluck(:color)
  end

  def section
    category&.parent
  end

  def ordered?
    self.class.connection.table_exists?(:order_items) && order_items.exists?
  end

  private
    def generate_slug
      self.slug = name.to_s.parameterize
    end

    def category_must_be_a_subcategory
      return if category.nil? || category.subcategory?

      errors.add(:category, :must_be_subcategory)
    end

    # A product that already appears in orders is hidden instead of deleted.
    # `OrderItem` arrives in stage 14, so the check waits for its table.
    def ensure_not_ordered
      return unless ordered?

      errors.add(:base, :ordered)
      throw :abort
    end
end
