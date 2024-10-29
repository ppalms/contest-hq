class CreateContests < ActiveRecord::Migration[8.0]
  def change
    create_table :contests do |t|
      t.string :name
      t.datetime :contest_start
      t.datetime :contest_end

      t.timestamps
    end
  end
end
