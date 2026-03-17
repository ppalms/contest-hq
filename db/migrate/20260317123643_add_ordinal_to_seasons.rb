class AddOrdinalToSeasons < ActiveRecord::Migration[8.1]
  def change
    add_column :seasons, :ordinal, :integer
    add_index :seasons, [ :account_id, :ordinal ], unique: true

    # Backfill existing seasons with sequential ordinals per account
    reversible do |dir|
      dir.up do
        # For each account, assign ordinals starting from 1 based on created_at
        execute <<-SQL
          WITH ranked_seasons AS (
            SELECT id,
                   ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY created_at ASC) as row_num
            FROM seasons
          )
          UPDATE seasons
          SET ordinal = (SELECT row_num FROM ranked_seasons WHERE ranked_seasons.id = seasons.id)
        SQL
      end
    end

    change_column_null :seasons, :ordinal, false
  end
end
