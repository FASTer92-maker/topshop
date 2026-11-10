# Demo catalog: 39 products across every subcategory of the two-level tree.
# Data lives in db/seeds/catalog.yml; the mono-colour placeholder image is
# picked from db/seeds/images/ by the first colour of the product.

require "yaml"

IMAGE_BY_COLOR = {
  "Чёрный" => "black",
  "Белый" => "white",
  "Молочный" => "white",
  "Серый" => "gray",
  "Бежевый" => "beige",
  "Табачный" => "tabacco",
  "Синий" => "navy",
  "Голубой" => "navy",
  "Зелёный" => "green",
  "Розовый" => "rose"
}.freeze

catalog = YAML.load_file(Rails.root.join("db", "seeds", "catalog.yml"))

catalog.each do |entry|
  category = Category.find_by!(slug: entry.fetch("category"))
  product = Product.find_or_initialize_by(slug: entry.fetch("name").parameterize)

  product.assign_attributes(
    name: entry.fetch("name"),
    category: category,
    price: entry.fetch("price"),
    description: entry.fetch("description"),
    active: true
  )
  product.save!

  next if product.image.attached?

  image_name = IMAGE_BY_COLOR.fetch(entry.fetch("colors").first, "gray")
  path = Rails.root.join("db", "seeds", "images", "#{image_name}.png")

  File.open(path, "rb") do |io|
    product.image.attach(io: io, filename: "#{product.slug}.png", content_type: "image/png")
  end
end
