class AddAccountToContests < ActiveRecord::Migration[8.0]
  def change
    add_reference :contests, :account, null: false, foreign_key: true
  end
end
