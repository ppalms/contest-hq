class CreateLargeEnsembles < ActiveRecord::Migration[8.0]
  def change
    create_table :large_ensembles do |t|
      t.string :name
      t.timestamps

      t.references :school, null: false, foreign_key: true
      t.references :performance_class, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
    end
  end
end
