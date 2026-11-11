module ApplicationHelper
  # Section links of the storefront menu, loaded once per request.
  def header_sections
    @header_sections ||= Category.sections.ordered.to_a
  end

  # Highlights the section link while browsing the section itself or any of
  # its subcategories.
  def catalog_section_current?(section)
    @category.present? && @category.section == section
  end

  # Items in the cart for the header counter. Does not create a cart for a user
  # who has never added anything.
  def cart_items_count
    authenticated? ? Current.user.cart&.items_count.to_i : 0
  end
end
