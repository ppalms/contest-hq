class AddMusicRequirementsToContests < ActiveRecord::Migration[8.1]
  def change
    add_column :contests, :required_prescribed_count, :integer, default: 1, null: false
    add_column :contests, :required_custom_count, :integer, default: 2, null: false
  end
end
