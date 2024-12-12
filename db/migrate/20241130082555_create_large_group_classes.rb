class CreateLargeGroupClasses < ActiveRecord::Migration[8.0]
  def change
    create_table :large_group_classes do |t|
      t.string :name
      t.timestamps

      t.references :account, null: false, foreign_key: true
    end
  end
end
