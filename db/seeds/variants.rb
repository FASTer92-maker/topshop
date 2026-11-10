# Demo variants: every colour of every product in 1-3 sizes with different
# stock levels (some are zero on purpose). Accessories get a single ONE SIZE.
# Stock is derived from the catalog position so re-running the seed is stable.

require "yaml"

catalog = YAML.load_file(Rails.root.join("db", "seeds", "catalog.yml"))

def color_code(color)
  color.parameterize.first(3).to_s.upcase.presence || "CLR"
end

def size_code(size)
  size == "ONE SIZE" ? "OS" : size
end

catalog.each_with_index do |entry, product_index|
  product = Product.find_by!(slug: entry.fetch("name").parameterize)

  entry.fetch("colors").each_with_index do |color, color_index|
    entry.fetch("sizes").each_with_index do |size, size_index|
      sku = [ entry.fetch("sku"), color_code(color), size_code(size) ].join("-")
      stock = (product_index + color_index * 2 + size_index * 3) % 7

      variant = Variant.find_or_initialize_by(sku: sku)
      variant.assign_attributes(product: product, size: size, color: color, stock: stock)
      variant.save!
    end
  end
end
