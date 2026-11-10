require "test_helper"

class VariantTest < ActiveSupport::TestCase
  test "fixture is valid" do
    assert variants(:men_jacket_m_black).valid?
  end

  test "normalizes the sku to upper case without spaces" do
    variant = Variant.new(sku: "  mj-ard-bel-xl  ")

    assert_equal "MJ-ARD-BEL-XL", variant.sku
  end

  test "capitalizes the colour" do
    variant = Variant.new(color: "  чёрный ")

    assert_equal "Чёрный", variant.color
  end

  test "requires a known size" do
    variant = variants(:men_jacket_m_black).dup
    variant.size = "XXXL"

    assert_not variant.valid?
    assert variant.errors.of_kind?(:size, :inclusion)
  end

  test "allows ONE SIZE for accessories" do
    assert Variant::SIZES.include?("ONE SIZE")
    assert variants(:hidden_bag_one_size).valid?
  end

  test "rejects a duplicate size and colour within one product" do
    variant = Variant.new(product: products(:men_jacket), size: "M", color: "Чёрный",
                          stock: 1, sku: "MJ-ARD-CHE-M-2")

    assert_not variant.valid?
    assert variant.errors.of_kind?(:size, :taken)
  end

  test "allows the same size in another colour" do
    variant = Variant.new(product: products(:men_jacket), size: "M", color: "Белый",
                          stock: 1, sku: "MJ-ARD-BEL-M")

    assert variant.valid?, variant.errors.full_messages.to_sentence
  end

  test "rejects a duplicate sku across products" do
    variant = Variant.new(product: products(:women_jacket), size: "XL", color: "Белый",
                          stock: 1, sku: variants(:men_jacket_m_black).sku)

    assert_not variant.valid?
    assert variant.errors.of_kind?(:sku, :taken)
  end

  test "rejects a negative or fractional stock" do
    variant = Variant.new(stock: -1)
    assert_not variant.valid?
    assert variant.errors.of_kind?(:stock, :greater_than_or_equal_to)

    variant.stock = 1.5
    assert_not variant.valid?
    assert variant.errors.of_kind?(:stock, :not_an_integer)
  end

  test "enforces the stock check constraint in the database" do
    variant = variants(:men_jacket_m_black)

    assert_raises(ActiveRecord::StatementInvalid) { variant.update_column(:stock, -1) }
  end

  test "in_stock scope returns only variants with stock" do
    assert_includes Variant.in_stock, variants(:men_jacket_m_black)
    assert_not_includes Variant.in_stock, variants(:men_jacket_l_black)
  end

  test "low_stock scope returns variants with three or fewer items" do
    assert_includes Variant.low_stock, variants(:men_jacket_m_tabacco)
    assert_not_includes Variant.low_stock, variants(:men_jacket_m_black)
  end

  test "by_size orders variants in the display order" do
    assert_equal %w[M M L], products(:men_jacket).variants.pluck(:size)
  end

  test "available? respects stock and product visibility" do
    assert variants(:men_jacket_m_black).available?
    assert_not variants(:men_jacket_m_black).available?(6)
    assert_not variants(:hidden_bag_one_size).available?
  end

  test "label joins size and colour" do
    assert_equal "M · Чёрный", variants(:men_jacket_m_black).label
  end
end
