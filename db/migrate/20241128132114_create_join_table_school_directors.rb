class CreateJoinTableSchoolDirectors < ActiveRecord::Migration[8.0]
  def change
    create_join_table :schools, :users, table_name: :school_directors do |t|
      t.references :account, null: false, foreign_key: true
      t.index :school_id
      t.index :user_id
      t.index [ :school_id, :user_id, :account_id ], unique: true, name: "index_school_directors_unique"
    end

    add_foreign_key :school_directors, :schools
    add_foreign_key :school_directors, :users
  end
end
