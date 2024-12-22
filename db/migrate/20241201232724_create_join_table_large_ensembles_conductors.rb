class CreateJoinTableLargeEnsemblesConductors < ActiveRecord::Migration[8.0]
  def change
    create_join_table :large_ensembles, :users, table_name: :large_ensemble_conductors do |t|
      t.references :account, null: false, foreign_key: true
      t.index [ :large_ensemble_id ]
      t.index [ :user_id ]
      t.index [ :large_ensemble_id, :user_id, :account_id ], unique: true, name: "index_large_ensemble_conductors_unique"

      t.timestamps
    end

    add_foreign_key :large_ensemble_conductors, :large_ensembles
    add_foreign_key :large_ensemble_conductors, :users
  end
end
