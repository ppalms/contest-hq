class ChangeScheduleDayTimeColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :schedule_days, :start_time, :time
    remove_column :schedule_days, :end_time, :time

    remove_column :schedule_blocks, :start_time, :time
    remove_column :schedule_blocks, :end_time, :time

    add_column :schedule_days, :start_time, :datetime, null: false
    add_column :schedule_days, :end_time, :datetime, null: false

    add_column :schedule_blocks, :start_time, :datetime, null: false
    add_column :schedule_blocks, :end_time, :datetime, null: false
  end
end
