require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "valid section generates its slug from the name" do
    category = Category.new(name: "Новинки")

    assert category.valid?
    assert_equal "novinki", category.slug
    assert category.section?
  end

  test "valid subcategory generates a slug prefixed with the section slug" do
    category = Category.new(name: "Рубашки", parent: categories(:men))

    assert category.valid?
    assert_equal "muzhskoe-rubashki", category.slug
    assert category.subcategory?
  end

  test "the same subcategory name is allowed under different sections" do
    assert_equal "Куртки", categories(:men_jackets).name
    assert_equal "Куртки", categories(:women_jackets).name
    assert_equal "muzhskoe-kurtki", categories(:men_jackets).slug
    assert_equal "zhenskoe-kurtki", categories(:women_jackets).slug
    assert categories(:men_jackets).valid?
    assert categories(:women_jackets).valid?
  end

  test "a duplicate section name is rejected" do
    category = Category.new(name: "Мужское")

    assert_not category.valid?
    assert category.errors.of_kind?(:name, :taken)
  end

  test "a duplicate name within the same parent is rejected" do
    category = Category.new(name: "Куртки", parent: categories(:men))

    assert_not category.valid?
    assert category.errors.of_kind?(:name, :taken)
  end

  test "a subcategory cannot be used as a parent" do
    category = Category.new(name: "Пуховики", parent: categories(:men_jackets))

    assert_not category.valid?
    assert category.errors.added?(:base, :parent_must_be_a_section)
  end

  test "a category cannot be its own parent" do
    section = categories(:men)
    section.parent = section

    assert_not section.valid?
    assert section.errors.added?(:base, :cannot_be_own_parent)
  end

  test "a section with subcategories cannot gain a parent" do
    section = categories(:men)
    section.parent = categories(:women)

    assert_not section.valid?
    assert section.errors.added?(:base, :section_has_subcategories)
  end

  test "a section with subcategories is not destroyed" do
    section = categories(:men)

    assert_not section.destroy
    assert section.errors.present?
  end

  test "a subcategory is destroyed" do
    assert_difference "Category.count", -1 do
      categories(:women_jackets).destroy!
    end
  end

  test "self_and_subcategory_ids includes the section and its subcategories" do
    assert_equal [ categories(:men).id, categories(:men_jackets).id ].sort,
                 categories(:men).self_and_subcategory_ids.sort
  end

  test "full_name joins a subcategory with its section" do
    assert_equal "Мужское", categories(:men).full_name
    assert_equal "Мужское › Куртки", categories(:men_jackets).full_name
  end

  test "to_param returns the slug" do
    assert_equal "muzhskoe", categories(:men).to_param
  end

  test "sections and ordered scopes return top-level sections in order" do
    assert_equal [ "Мужское", "Женское", "Аксессуары" ], Category.sections.ordered.pluck(:name)
  end

  test "rejects a malformed slug" do
    category = Category.new(name: "Куртки", parent: categories(:men), slug: "Bad Slug")

    assert_not category.valid?
    assert category.errors.of_kind?(:slug, :invalid)
  end

  test "squishes the name" do
    category = Category.new(name: "  Куртки   Зимние ")

    assert_equal "Куртки Зимние", category.name
  end
end
