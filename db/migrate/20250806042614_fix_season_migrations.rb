class FixSeasonMigrations < ActiveRecord::Migration[8.0]
  def up
    # This migration fixes the issue where AddSeasonToContests failed
    # due to trying to create an index that already exists

    # First, ensure the seasons table exists (in case CreateSeasons didn't complete)
    unless table_exists?(:seasons)
      create_table :seasons do |t|
        t.string :name, null: false
        t.boolean :archived, default: false, null: false
        t.references :account, null: false, foreign_key: true
        t.timestamps
      end

      add_index :seasons, [ :account_id, :name ], unique: true unless index_exists?(:seasons, [ :account_id, :name ])
      add_index :seasons, :account_id unless index_exists?(:seasons, :account_id)
    end

    # Handle the contests table season reference
    unless column_exists?(:contests, :season_id)
      # Column doesn't exist, add it properly
      add_reference :contests, :season, null: true, foreign_key: true
    else
      # Column exists, but we need to ensure foreign key and index are properly set
      unless foreign_key_exists?(:contests, :seasons)
        add_foreign_key :contests, :seasons
      end

      # The index might or might not exist, check and add only if needed
      unless index_exists?(:contests, :season_id)
        add_index :contests, :season_id
      end
    end

    # Update the schema_migrations table to mark the problematic migration as completed
    # This prevents Rails from trying to run AddSeasonToContests again
    execute "INSERT INTO schema_migrations (version) VALUES ('20250131120001') ON CONFLICT (version) DO NOTHING"
    execute "INSERT INTO schema_migrations (version) VALUES ('20250131120002') ON CONFLICT (version) DO NOTHING"
  end

  def down
    # Remove season reference from contests
    if column_exists?(:contests, :season_id)
      remove_foreign_key :contests, :seasons if foreign_key_exists?(:contests, :seasons)
      remove_reference :contests, :season
    end

    # Remove seasons table
    drop_table :seasons if table_exists?(:seasons)

    # Remove the schema_migrations entries
    execute "DELETE FROM schema_migrations WHERE version IN ('20250131120001', '20250131120002')"
  end
end
