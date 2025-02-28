class AddAbbrAndOrdinalToPerformanceClass < ActiveRecord::Migration[8.0]
  def change
    add_column :performance_classes, :abbreviation, :string, null: true, limit: 10
    add_column :performance_classes, :ordinal, :integer, null: true

    PerformanceClass.reset_column_information

    subquery = PerformanceClass.select('DISTINCT ON (account_id) *').order(:account_id, :created_at).to_sql

    PerformanceClass.find_by_sql(subquery).each do |performance_class|
      PerformanceClass.where(account_id: performance_class.account_id).order(:created_at).each.with_index(1) do |pc, index|
        pc.update_columns(ordinal: index)
      end
    end

    change_column_null :performance_classes, :ordinal, false

    add_index :performance_classes, [ :account_id, :ordinal ], unique: true
  end
end
