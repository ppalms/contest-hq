class AddAbbrAndOrdinalToPerformanceClass < ActiveRecord::Migration[8.0]
  def change
    add_column :performance_classes, :abbreviation, :string, null: true, limit: 10
    add_column :performance_classes, :ordinal, :integer, null: true

    PerformanceClass.reset_column_information

    PerformanceClass.unscoped.order(:account_id, :created_at).group_by(&:account_id).each do |_account_id, performance_classes|
      performance_classes.each.with_index(1) do |performance_class, index|
        performance_class.update_columns(ordinal: index)
      end
    end

    change_column_null :performance_classes, :ordinal, false

    add_index :performance_classes, [ :account_id, :ordinal ], unique: true
  end
end
