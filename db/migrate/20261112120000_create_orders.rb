class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :number, null: false
      t.integer :status, null: false, default: 0
      t.decimal :subtotal, precision: 10, scale: 2, null: false, default: 0
      t.decimal :delivery_price, precision: 10, scale: 2, null: false, default: 0
      t.decimal :total, precision: 10, scale: 2, null: false, default: 0
      t.string :full_name, null: false
      t.string :phone, null: false
      t.text :address, null: false
      t.text :comment

      t.timestamps
    end

    add_index :orders, :number, unique: true
    add_index :orders, :status
    add_index :orders, :created_at
    add_check_constraint :orders, "status BETWEEN 0 AND 5", name: "orders_status_check"
    add_check_constraint :orders, "subtotal >= 0", name: "orders_subtotal_check"
    add_check_constraint :orders, "delivery_price >= 0", name: "orders_delivery_price_check"
    add_check_constraint :orders, "total = subtotal + delivery_price", name: "orders_total_check"
  end
end
