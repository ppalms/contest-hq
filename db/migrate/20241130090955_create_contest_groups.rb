class CreateContestGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :contest_groups do |t|
      t.string :name
      t.timestamps

      t.references :organization, null: false, foreign_key: true
      t.references :contest_group_class, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
    end
  end
end
