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

  scope :active, -> { where(active: true) }
  scope :newest, -> { order(created_at: :desc) }
  scope :in_stock, -> { where(id: Variant.in_stock.select(:product_id)) }

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
