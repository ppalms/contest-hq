class CreateContestGroupClasses < ActiveRecord::Migration[8.0]
  def change
    create_table :contest_group_classes do |t|
      t.string :name
      t.timestamps

      t.references :account, null: false, foreign_key: true
    end
  end
end
