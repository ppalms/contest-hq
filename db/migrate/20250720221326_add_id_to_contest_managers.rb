class AddIdToContestManagers < ActiveRecord::Migration[8.0]
  def change
    add_column :contest_managers, :id, :primary_key
  end
end
