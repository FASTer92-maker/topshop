class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :products, :slug, unique: true
    add_index :products, :name
    add_index :products, :active
    add_index :products, :price
    add_index :products, :created_at
    add_check_constraint :products, "price >= 0", name: "products_price_check"
  end
end
