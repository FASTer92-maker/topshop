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
end
