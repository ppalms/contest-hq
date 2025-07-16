class CreateContestSeasons < ActiveRecord::Migration[8.0]
  def change
    create_table :contest_seasons do |t|
      t.string :name, null: false
      t.references :account, null: false, foreign_key: true

      t.timestamps

      t.index [:name, :account_id], unique: true
    end
  end
end
