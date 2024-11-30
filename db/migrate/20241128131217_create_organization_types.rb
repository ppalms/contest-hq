class CreateOrganizationTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :organization_types do |t|
      t.string :name
      t.references :account, null: false, foreign_key: true
      t.timestamps
    end
  end
end
