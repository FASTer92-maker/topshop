class CreateVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string :size, null: false
      t.string :color, null: false
      t.integer :stock, null: false, default: 0
      t.string :sku, null: false

      t.timestamps
    end

    add_index :variants, [ :product_id, :size, :color ], unique: true
    add_index :variants, :sku, unique: true
    add_index :variants, :size
    add_index :variants, :color
    add_check_constraint :variants, "stock >= 0", name: "variants_stock_check"
  end
end
