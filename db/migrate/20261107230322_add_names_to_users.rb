class AddNamesToUsers < ActiveRecord::Migration[8.1]
  def change
    # The users table is still empty everywhere, so NOT NULL needs no default.
    add_column :users, :first_name, :string, null: false
    add_column :users, :last_name, :string, null: false
  end
end
