class CreateContests < ActiveRecord::Migration[8.1]
  def change
    create_table :contests do |t|
      t.string :name
      t.date :start_date
      t.time :start_time
      t.date :end_date
      t.time :end_time

      t.timestamps
    end
  end
end
