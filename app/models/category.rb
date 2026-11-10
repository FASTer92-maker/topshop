class Category < ApplicationRecord
  SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  belongs_to :parent, class_name: "Category", optional: true, inverse_of: :subcategories
  has_many :subcategories, class_name: "Category", foreign_key: :parent_id,
           dependent: :restrict_with_error, inverse_of: :parent
  has_many :products, dependent: :restrict_with_error

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, length: { maximum: 100 },
                   uniqueness: { scope: :parent_id, case_sensitive: false }
  validates :slug, presence: true, uniqueness: true, format: { with: SLUG_FORMAT }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :parent_must_be_a_section
  validate :section_with_subcategories_cannot_gain_parent
  validate :not_own_parent

  before_validation :generate_slug, if: -> { slug.blank? }

  scope :sections, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:position, :name) }

  def to_param
    slug
  end

  def section?
    parent_id.nil?
  end

  def subcategory?
    !section?
  end

  def section
    parent || self
  end

  def self_and_subcategory_ids
    [ id, *subcategories.ids ]
  end

  def full_name
    subcategory? ? "#{parent.name} › #{name}" : name
  end

  private
    def parent_must_be_a_section
      return if parent.nil? || parent_id == id || parent.section?

      errors.add(:base, :parent_must_be_a_section)
    end

    def section_with_subcategories_cannot_gain_parent
      return if parent_id.nil? || subcategories.empty?

      errors.add(:base, :section_has_subcategories)
    end

    def not_own_parent
      return unless id && parent_id == id

      errors.add(:base, :cannot_be_own_parent)
    end

    def generate_slug
      self.slug = parent ? "#{parent.slug}-#{name.parameterize}" : name.parameterize
    end
end
