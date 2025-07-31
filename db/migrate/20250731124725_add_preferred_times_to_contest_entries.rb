class AddPreferredTimesToContestEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :contest_entries, :preferred_time_start, :time
    add_column :contest_entries, :preferred_time_end, :time
  end
end