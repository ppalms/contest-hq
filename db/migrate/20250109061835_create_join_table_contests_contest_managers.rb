class CreateJoinTableContestsContestManagers < ActiveRecord::Migration[8.0]
  def change
    create_join_table :contests, :users, table_name: :contest_managers do |t|
      t.references :account, null: false, foreign_key: true
      t.foreign_key :contests
      t.foreign_key :users

      t.index [ :contest_id ]
      t.index [ :user_id ]
      t.index [ :account_id, :contest_id, :user_id ], unique: true, name: "index_contest_managers_unique"

      t.timestamps
    end
  end
end
