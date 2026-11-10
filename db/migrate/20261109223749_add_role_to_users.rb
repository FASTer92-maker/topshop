class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :integer, null: false, default: 0
    add_index :users, :role
    add_check_constraint :users, "role IN (0, 1)", name: "users_role_check"
  end
end
