require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "valid product generates its slug from the name" do
    product = Product.new(category: categories(:men_jackets), name: "Куртка «Тест»", price: 1000)

    assert product.valid?, product.errors.full_messages.to_sentence
    assert_equal "kurtka-test", product.slug
    assert product.active?
  end

  test "squishes the name" do
    product = Product.new(name: "  Куртка   Тест ")

    assert_equal "Куртка Тест", product.name
  end

  test "requires a name" do
    product = Product.new(category: categories(:men_jackets), price: 1000)

    assert_not product.valid?
    assert product.errors.of_kind?(:name, :blank)
  end

  test "rejects a section as a category" do
    product = Product.new(category: categories(:men), name: "Куртка", price: 1000)

    assert_not product.valid?
    assert product.errors.added?(:category, :must_be_subcategory)
  end

  test "rejects a negative price" do
    product = Product.new(category: categories(:men_jackets), name: "Куртка", price: -1)

    assert_not product.valid?
    assert product.errors.of_kind?(:price, :greater_than_or_equal_to)
  end

  test "enforces the price check constraint in the database" do
    product = products(:men_jacket)

    assert_raises(ActiveRecord::StatementInvalid) { product.update_column(:price, -1) }
  end

  test "rejects a duplicate slug" do
    product = Product.new(category: categories(:men_jackets), name: "Другая куртка", price: 1000,
                          slug: products(:men_jacket).slug)

    assert_not product.valid?
    assert product.errors.of_kind?(:slug, :taken)
  end

  test "rejects a malformed slug" do
    product = Product.new(category: categories(:men_jackets), name: "Куртка", price: 1000, slug: "Bad Slug")

    assert_not product.valid?
    assert product.errors.of_kind?(:slug, :invalid)
  end

  test "accepts a png image" do
    product = products(:men_jacket)

    File.open(file_fixture("product.png"), "rb") do |io|
      product.image.attach(io: io, filename: "product.png", content_type: "image/png")
    end

    assert product.valid?, product.errors.full_messages.to_sentence
  end

  test "rejects an image of an unsupported type" do
    product = products(:men_jacket)

    File.open(file_fixture("product.txt"), "rb") do |io|
      product.image.attach(io: io, filename: "product.txt", content_type: "text/plain")
    end

    assert_not product.valid?
    assert product.errors.of_kind?(:image, :content_type)
  end

  test "rejects an image larger than 5 MB" do
    product = products(:men_jacket)

    product.image.attach(
      io: StringIO.new("x" * (5.megabytes + 1)),
      filename: "big.png",
      content_type: "image/png"
    )

    assert_not product.valid?
    assert product.errors.of_kind?(:image, :file_size)
  end

  test "active scope returns only visible products" do
    assert_includes Product.active, products(:men_jacket)
    assert_not_includes Product.active, products(:hidden_product)
  end

  test "in_category for a section includes the products of its subcategories" do
    products = Product.in_category(categories(:women))

    assert_includes products, products(:women_jacket)
    assert_not_includes products, products(:men_jacket)
  end

  test "in_category for a subcategory includes only its own products" do
    products = Product.in_category(categories(:men_jackets))

    assert_includes products, products(:men_jacket)
    assert_not_includes products, products(:women_jacket)
  end

  test "in_stock scope ignores products without stock" do
    assert_includes Product.in_stock, products(:men_jacket)
    assert_not_includes Product.in_stock, products(:sold_out_product)
  end

  test "in_stock combined with active hides a hidden product that still has stock" do
    assert_includes Product.in_stock, products(:hidden_product)
    assert_not_includes Product.active.in_stock, products(:hidden_product)
  end

  test "in_stock? tells whether any variant has stock" do
    assert products(:men_jacket).in_stock?
    assert_not products(:sold_out_product).in_stock?
  end

  test "available_sizes returns in-stock sizes in display order without duplicates" do
    assert_equal [ "M" ], products(:men_jacket).available_sizes
  end

  test "colors returns the unique colours of the variants" do
    assert_equal [ "Табачный", "Чёрный" ], products(:men_jacket).colors
  end

  test "section returns the parent of the category" do
    assert_equal categories(:men), products(:men_jacket).section
  end

  test "to_param returns the slug" do
    assert_equal "kurtka-arden", products(:men_jacket).to_param
  end

  test "destroying a product removes its variants" do
    product = products(:men_jacket)
    variants_count = product.variants.count

    assert_difference "Variant.count", -variants_count do
      product.destroy!
    end
  end

  test "admin_search finds products by name" do
    assert_equal [ products(:men_jacket) ], Product.admin_search("Арден").to_a
  end

  test "admin_search finds products by variant sku" do
    assert_equal [ products(:women_jacket) ], Product.admin_search("ZJ-LNA-CHE-S").to_a
  end

  test "admin_search with a blank query returns everything" do
    assert_equal Product.count, Product.admin_search("   ").count
  end

  test "search finds products by name case-insensitively" do
    assert_includes Product.search("АРДЕН"), products(:men_jacket)
    assert_not_includes Product.search("арден"), products(:women_jacket)
  end

  test "search looks into the description" do
    assert_includes Product.search("хлопок"), products(:men_jacket)
    assert_not_includes Product.search("хлопок"), products(:women_jacket)
  end

  test "search escapes the SQL wildcards" do
    # Only the product whose description contains a literal "100%" matches.
    assert_equal [ products(:men_jacket) ], Product.search("%").to_a
    assert_empty Product.search("_")
  end

  test "search with a blank query returns everything" do
    assert_equal Product.count, Product.search("   ").count
  end

  test "price_from and price_to filter by the price range" do
    assert_equal [ products(:women_jacket) ], Product.price_from(13_000).to_a
    assert_equal [ products(:sold_out_product) ], Product.active.price_to(7_000).to_a
    assert_equal products(:men_jacket), Product.price_from(12_000).price_to(13_000).sole
  end

  test "price filters ignore malformed and negative values" do
    assert_equal Product.count, Product.price_from("дорого").count
    assert_equal Product.count, Product.price_to("").count
    assert_equal Product.count, Product.price_from(-1).count
  end

  test "price filters accept spaces and a decimal comma" do
    assert_equal [ products(:women_jacket) ], Product.price_from("13 000").to_a
    assert_equal [ products(:women_jacket) ], Product.price_from("13800,50").to_a
  end

  test "with_size finds only products with that size in stock" do
    assert_includes Product.with_size("M"), products(:men_jacket)
    assert_not_includes Product.with_size("L"), products(:men_jacket),
                        "L exists but has no stock"
  end

  test "with_size ignores an unknown size" do
    assert_equal Product.count, Product.with_size("XXXL").count
  end

  test "with_color finds products by colour case-insensitively" do
    assert_includes Product.with_color("чёрный"), products(:men_jacket)
    assert_includes Product.with_color("ЧЁРНЫЙ"), products(:women_jacket)
    assert_not_includes Product.with_color("синий"), products(:men_jacket)
  end

  test "in_stock excludes products whose variants are sold out" do
    assert_includes Product.in_stock, products(:men_jacket)
    assert_not_includes Product.in_stock, products(:sold_out_product)
  end

  test "variant filters do not duplicate a product with several matching variants" do
    assert_equal 1, Product.with_size("M").where(id: products(:men_jacket).id).count
  end

  test "sorted_by orders products by price ascending and descending" do
    prices = Product.active.sorted_by("price_asc").pluck(:price)

    assert_equal prices.sort, prices

    prices = Product.active.sorted_by("price_desc").pluck(:price)

    assert_equal prices.sort.reverse, prices
  end

  test "sorted_by falls back to the default order for unknown keys" do
    assert_equal Product.active.sorted_by("drop table").to_sql,
                 Product.active.sorted_by("default").to_sql
  end

  test "filter_by applies every filter at once" do
    products = Product.active.filter_by(
      "q" => "куртка", "size" => "M", "color" => "Чёрный",
      "price_from" => "10000", "price_to" => "13000", "in_stock" => "1"
    )

    assert_equal [ products(:men_jacket).id ], products.ids
  end

  test "filter_by ignores malformed values instead of raising" do
    products = Product.active.filter_by(
      "size" => "XXXL", "color" => "", "price_from" => "abc",
      "price_to" => "-5", "sort" => "price; DROP TABLE products"
    )

    assert_equal Product.active.count, products.count
  end

  test "filter_by with an unknown colour finds nothing" do
    assert_empty Product.active.filter_by("color" => "нет такого")
  end

  test "filter_by treats a zero checkbox value as not ticked" do
    assert_equal Product.active.count, Product.active.filter_by("in_stock" => "0").count
  end

  test "filter_by with no parameters keeps every active product" do
    assert_equal Product.active.count, Product.active.filter_by({}).count
  end
end
