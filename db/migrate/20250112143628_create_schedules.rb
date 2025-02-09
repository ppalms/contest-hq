class CreateSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :schedules do |t|
      t.timestamps

      t.references :contest, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
    end

    create_table :schedule_days do |t|
      t.date :date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false

      t.references :schedule, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
    end

    create_table :rooms do |t|
      t.string :room_number, null: false
      t.string :name

      t.references :schedule, null: true, foreign_key: true
      t.references :account, null: false, foreign_key: true

      t.index [ :room_number, :schedule_id ], unique: true
    end

    create_table :performance_sequences do |t|
      t.references :schedule, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
    end

    create_table :performance_steps do |t|
      t.text :name, null: false
      t.integer :duration, null: false
      t.integer :ordinal, null: false

      t.references :performance_sequence, null: false, foreign_key: true
      t.references :room, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true

      t.index [ :ordinal, :performance_sequence_id ], unique: true
    end

    create_table :schedule_blocks do |t|
      t.time :start_time, null: false
      t.time :end_time, null: false

      t.references :room, null: false, foreign_key: true
      t.references :schedule_day, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
    end
  end
end
