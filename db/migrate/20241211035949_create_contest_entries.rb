class CreateContestEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :contest_entries do |t|
      t.references :contest, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :contest_group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
