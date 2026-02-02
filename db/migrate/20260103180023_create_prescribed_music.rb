class CreatePrescribedMusic < ActiveRecord::Migration[8.1]
  def change
    create_table :prescribed_musics do |t|
      t.string :title, null: false
      t.string :composer, null: false
      t.references :account, null: false, foreign_key: true
      t.references :season, null: false, foreign_key: true
      t.references :school_class, null: false, foreign_key: true

      t.timestamps

      t.index [ :account_id, :season_id, :school_class_id ]
    end
  end
end
