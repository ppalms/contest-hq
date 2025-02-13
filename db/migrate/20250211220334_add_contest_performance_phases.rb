class AddContestPerformancePhases < ActiveRecord::Migration[8.0]
  def change
    drop_table :performance_steps
    drop_table :performance_sequences
    drop_table :schedule_blocks
    drop_table :rooms

    create_table :rooms do |t|
      t.string :room_number, null: false
      t.string :name

      t.references :contest, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true

      t.index [ :room_number, :contest_id ], unique: true
    end

    create_table :performance_phases do |t|
      t.text :name, null: false
      t.integer :duration, null: false
      t.integer :ordinal, null: false

      t.references :room, null: false, foreign_key: true
      t.references :contest, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true

      t.index [ :ordinal, :contest_id ], unique: true
    end
  end
end
