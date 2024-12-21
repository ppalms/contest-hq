class CreateJoinTableContestsSchoolClasses < ActiveRecord::Migration[8.0]
  def change
    create_join_table :contests, :school_classes do |t|
      t.references :account, null: false, foreign_key: true
      t.index [ :contest_id, :school_class_id ]
      t.index [ :school_class_id, :contest_id ]
      t.index [ :account_id, :contest_id, :school_class_id ], unique: true
    end

    add_foreign_key :contests_school_classes, :contests
    add_foreign_key :contests_school_classes, :school_classes
  end
end
