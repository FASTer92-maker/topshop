class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :parent, foreign_key: { to_table: :categories }
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    # Two top-level sections cannot share a name; the same subcategory name is
    # allowed under different sections (NULLS NOT DISTINCT needs PostgreSQL 15+).
    # The raw SQL string is required so `lower(name)` is used as an expression.
    add_index :categories, "parent_id, lower(name)",
              unique: true, nulls_not_distinct: true,
              name: "index_categories_on_parent_id_and_lower_name"
    add_index :categories, :slug, unique: true
    add_check_constraint :categories, "parent_id <> id", name: "categories_parent_id_not_self_check"
  end
end
