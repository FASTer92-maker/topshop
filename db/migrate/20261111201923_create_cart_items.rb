class CreateCartItems < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true, index: false
      t.references :variant, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1

      t.timestamps
    end

    # The composite index also serves lookups by cart_id alone.
    add_index :cart_items, [ :cart_id, :variant_id ], unique: true
    add_check_constraint :cart_items, "quantity > 0", name: "cart_items_quantity_check"
  end
end
