class CreateJoinTableContestGroupsConductors < ActiveRecord::Migration[8.0]
  def change
    create_join_table :contest_groups, :users, table_name: :contest_group_conductors do |t|
      t.references :account, null: false, foreign_key: true
      t.index [ :contest_group_id, :account_id ]
      t.index [ :user_id, :account_id ]
      t.index [ :contest_group_id, :user_id, :account_id ], unique: true

      t.timestamps
    end

    add_foreign_key :contest_group_conductors, :contest_groups
    add_foreign_key :contest_group_conductors, :users
  end
end
