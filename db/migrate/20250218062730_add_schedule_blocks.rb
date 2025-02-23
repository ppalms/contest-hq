class AddScheduleBlocks < ActiveRecord::Migration[8.0]
  def change
    create_table :schedule_blocks do |t|
      t.time :start_time, null: false
      t.time :end_time, null: false

      t.references :room, null: false, foreign_key: true
      t.references :schedule_day, null: false, foreign_key: true
      t.references :contest_entry, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
    end
  end
end
