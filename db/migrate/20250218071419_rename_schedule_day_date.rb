class RenameScheduleDayDate < ActiveRecord::Migration[8.0]
  def change
    rename_column :schedule_days, :date, :schedule_date
  end
end
