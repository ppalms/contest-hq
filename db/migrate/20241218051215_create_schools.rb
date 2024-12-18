class CreateSchools < ActiveRecord::Migration[8.0]
  def change
    create_table :schools do |t|
      t.string :name
      t.timestamps

      t.references :school_class, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
    end
  end
end
