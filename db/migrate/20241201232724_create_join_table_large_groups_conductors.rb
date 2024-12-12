class CreateJoinTableLargeGroupsConductors < ActiveRecord::Migration[8.0]
  def change
    create_join_table :large_groups, :users, table_name: :large_group_conductors do |t|
      t.references :account, null: false, foreign_key: true
      t.index [ :large_group_id, :account_id ]
      t.index [ :user_id, :account_id ]
      t.index [ :large_group_id, :user_id, :account_id ], unique: true

      t.timestamps
    end

    add_foreign_key :large_group_conductors, :large_groups
    add_foreign_key :large_group_conductors, :users
  end
end
