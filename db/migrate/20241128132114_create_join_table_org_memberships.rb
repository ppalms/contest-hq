class CreateJoinTableOrgMemberships < ActiveRecord::Migration[8.0]
  def change
    create_join_table :organizations, :users, table_name: :org_memberships do |t|
      t.references :account, null: false, foreign_key: true
      t.index :organization_id
      t.index :user_id
      t.index [ :organization_id, :user_id, :account_id ], unique: true
    end

    add_foreign_key :org_memberships, :organizations
    add_foreign_key :org_memberships, :users
  end
end
