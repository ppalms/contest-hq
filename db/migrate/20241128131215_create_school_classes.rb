class CreateSchoolClasses < ActiveRecord::Migration[8.0]
  def change
    create_table :school_classes do |t|
      t.string :name
      t.integer :ordinal
      t.timestamps

      t.references :account, null: false, foreign_key: true
    end

    add_index :school_classes, [ :account_id, :ordinal ], unique: true
  end
end
