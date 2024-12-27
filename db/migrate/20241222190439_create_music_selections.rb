class CreateMusicSelections < ActiveRecord::Migration[8.0]
  def change
    create_table :music_selections do |t|
      t.string :title
      t.string :composer
      t.timestamps

      t.references :contest_entry, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.index [ :account_id, :contest_entry_id ]
    end
  end
end
