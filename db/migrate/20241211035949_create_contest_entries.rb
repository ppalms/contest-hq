class CreateContestEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :contest_entries do |t|
      t.references :contest, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :large_ensemble, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
