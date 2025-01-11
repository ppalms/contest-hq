class AddStartEndTimeToContests < ActiveRecord::Migration[8.0]
  def change
    add_column :contests, :start_time, :time
    add_column :contests, :end_time, :time
  end
end
