class AddTimestampsToAccounts < ActiveRecord::Migration[8.0]
  def change
    change_table :accounts do |t|
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }, null: false
    end
  end
end
