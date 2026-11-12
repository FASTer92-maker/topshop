class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :variant, null: false, foreign_key: true
      t.string :product_name, null: false
      t.string :size, null: false
      t.string :color, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.integer :quantity, null: false

      t.timestamps
    end

    add_check_constraint :order_items, "unit_price >= 0", name: "order_items_unit_price_check"
    add_check_constraint :order_items, "quantity > 0", name: "order_items_quantity_check"
  end
end
