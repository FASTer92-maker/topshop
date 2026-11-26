module AdminHelper
  # Underlined active tab in the admin header, same rhythm as the storefront nav.
  def admin_nav_class(section)
    base = "border-b border-transparent pb-1 transition-colors duration-300"
    active = controller_path.start_with?("admin/#{section}")

    "#{base} #{active ? "border-accent text-ink" : "text-muted hover:border-accent hover:text-ink"}"
  end
end
