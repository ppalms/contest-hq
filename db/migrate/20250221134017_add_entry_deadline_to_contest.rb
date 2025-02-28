class AddEntryDeadlineToContest < ActiveRecord::Migration[8.0]
  def change
    add_column :contests, :entry_deadline, :datetime
  end
end
