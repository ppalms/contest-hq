class CreateSeasons < ActiveRecord::Migration[8.0]
  def change
    create_table :seasons do |t|
      t.string :name, null: false
      t.boolean :archived, default: false, null: false
      t.references :account, null: false, foreign_key: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }, null: false
    end

    add_index :seasons, [ :account_id, :name ], unique: true unless index_exists?(:seasons, [ :account_id, :name ])
    add_index :seasons, :account_id unless index_exists?(:seasons, :account_id)
  end
end
