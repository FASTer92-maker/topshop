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
end
