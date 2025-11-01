class AddDisplayNameToRoles < ActiveRecord::Migration[8.1]
  def change
    add_column :roles, :display_name, :string

    reversible do |dir|
      dir.up do
        Role.reset_column_information
        Role.find_by(name: "SysAdmin")&.update!(display_name: "System Admin")
        Role.find_by(name: "AccountAdmin")&.update!(display_name: "Account Admin")
        Role.find_by(name: "Director")&.update!(display_name: "Director")
        Role.find_by(name: "Manager")&.update!(display_name: "Manager")
        Role.find_by(name: "Judge")&.update!(display_name: "Judge")
      end
    end

    change_column_null :roles, :display_name, false
  end
end
