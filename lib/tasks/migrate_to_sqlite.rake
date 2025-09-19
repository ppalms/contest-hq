namespace :db do
  namespace :migrate do
    desc "Export PostgreSQL data and import to SQLite for production migration"
    task postgres_to_sqlite: :environment do
      puts "🔄 Starting PostgreSQL to SQLite migration..."

      # Check if we're in the right environment
      unless Rails.env.production?
        puts "⚠️  This task should only be run in production environment"
        puts "   Current environment: #{Rails.env}"
        exit 1
      end

      # Check database configuration
      unless ActiveRecord::Base.connection.adapter_name == "SQLite"
        puts "❌ Current database is not SQLite. Please ensure database.yml is configured for SQLite."
        exit 1
      end

      puts "📊 Exporting data from PostgreSQL..."

      # PostgreSQL connection details (from environment or secrets)
      pg_config = {
        host: ENV["OLD_DB_HOST"] || "167.71.21.241",
        port: ENV["OLD_POSTGRES_PORT"] || 5432,
        database: ENV["OLD_POSTGRES_DB"] || "contest_hq_production",
        username: ENV["OLD_POSTGRES_USER"],
        password: ENV["OLD_POSTGRES_PASSWORD"]
      }

      # Verify PostgreSQL credentials are available
      if pg_config[:username].blank? || pg_config[:password].blank?
        puts "❌ PostgreSQL credentials not found in environment variables:"
        puts "   Required: OLD_POSTGRES_USER, OLD_POSTGRES_PASSWORD"
        puts "   Optional: OLD_DB_HOST, OLD_POSTGRES_PORT, OLD_POSTGRES_DB"
        exit 1
      end

      # Connect to PostgreSQL
      pg_connection = nil
      begin
        require "pg"
        pg_connection = PG.connect(
          host: pg_config[:host],
          port: pg_config[:port],
          dbname: pg_config[:database],
          user: pg_config[:username],
          password: pg_config[:password]
        )
        puts "✅ Connected to PostgreSQL database"
      rescue PG::Error => e
        puts "❌ Failed to connect to PostgreSQL: #{e.message}"
        exit 1
      end

      # Get list of all tables from PostgreSQL
      tables_query = <<~SQL
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_type = 'BASE TABLE'
          AND table_name NOT IN ('ar_internal_metadata', 'schema_migrations')
        ORDER BY table_name;
      SQL

      all_tables = pg_connection.exec(tables_query).map { |row| row["table_name"] }

      # Define migration order respecting foreign key dependencies
      # Tables with no dependencies first, then tables that depend on them
      table_order = [
        # Base tables with no foreign key dependencies
        "accounts",
        "seasons",
        "performance_classes",

        # Tables depending on accounts/seasons/performance_classes
        "users",
        "school_classes",
        "schools",
        "contests",

        # Tables depending on schools/users
        "school_directors",
        "large_ensembles",
        "roles",
        "user_roles",

        # Tables depending on contests/users/large_ensembles
        "contest_managers",
        "contest_entries",
        "contests_school_classes",
        "large_ensemble_conductors",
        "rooms",

        # Tables depending on contest_entries/contests/rooms
        "music_selections",
        "performance_phases",
        "schedules",

        # Tables depending on schedules/performance_phases
        "schedule_days",
        "schedule_blocks",

        # Session table (likely no dependencies)
        "sessions"
      ]

      # Ensure all tables from database are included in our order
      missing_tables = all_tables - table_order
      if missing_tables.any?
        puts "⚠️  Warning: Tables not in migration order will be added at end: #{missing_tables.join(', ')}"
        table_order += missing_tables
      end

      # Only migrate tables that actually exist
      pg_tables = table_order.select { |table| all_tables.include?(table) }
      puts "📋 Found #{pg_tables.length} tables to migrate: #{pg_tables.join(', ')}"

      # Start transaction for SQLite
      ActiveRecord::Base.transaction do
        # Temporarily disable foreign key checks for the migration
        ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF")
        migrated_records = 0

        pg_tables.each do |table_name|
          puts "📦 Migrating table: #{table_name}"

          # Get data from PostgreSQL (handle tables without id column)
          begin
            pg_data = pg_connection.exec("SELECT * FROM #{table_name} ORDER BY id")
          rescue PG::UndefinedColumn => e
            if e.message.include?("column \"id\" does not exist")
              # Table doesn't have an id column, just get all data
              pg_data = pg_connection.exec("SELECT * FROM #{table_name}")
            else
              raise e
            end
          end
          record_count = pg_data.ntuples

          if record_count == 0
            puts "   ⏩ Empty table, skipping"
            next
          end

          # Prepare column names
          column_names = pg_data.fields

          # Clear existing SQLite table data (in case of re-run)
          ActiveRecord::Base.connection.execute("DELETE FROM #{table_name}")

          # Insert data into SQLite
          pg_data.each_with_index do |row, index|
            values = row.values.map do |value|
              case value
              when nil
                "NULL"
              when String
                "'#{value.gsub("'", "''")}'"  # Escape single quotes
              when Time, Date
                "'#{value}'"
              else
                value
              end
            end

            insert_sql = "INSERT INTO #{table_name} (#{column_names.join(', ')}) VALUES (#{values.join(', ')})"

            begin
              ActiveRecord::Base.connection.execute(insert_sql)
            rescue => e
              puts "   ❌ Error inserting record #{index + 1}: #{e.message}"
              puts "   SQL: #{insert_sql}"
              raise e
            end

            # Progress indicator
            if (index + 1) % 100 == 0 || (index + 1) == record_count
              puts "   📈 Progress: #{index + 1}/#{record_count} records"
            end
          end

          migrated_records += record_count
          puts "   ✅ Migrated #{record_count} records from #{table_name}"
        end

        puts "🎉 Migration completed successfully!"
        puts "📊 Total records migrated: #{migrated_records}"

        # Verify data integrity
        puts "🔍 Verifying data integrity..."
        verification_results = {}

        pg_tables.each do |table_name|
          pg_count = pg_connection.exec("SELECT COUNT(*) FROM #{table_name}").getvalue(0, 0).to_i
          sqlite_count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{table_name}").first.first

          verification_results[table_name] = {
            postgresql: pg_count,
            sqlite: sqlite_count,
            match: pg_count == sqlite_count
          }
        end

        # Display verification results
        puts "\n📋 Data Verification Results:"
        verification_results.each do |table, counts|
          status = counts[:match] ? "✅" : "❌"
          puts "   #{status} #{table}: PostgreSQL=#{counts[:postgresql]}, SQLite=#{counts[:sqlite]}"
        end

        # Check if all verifications passed
        all_match = verification_results.values.all? { |counts| counts[:match] }

        if all_match
          puts "\n🎉 All data verification checks passed!"
        else
          puts "\n❌ Some verification checks failed. Rolling back transaction."
          raise "Data verification failed"
        end

        # Re-enable foreign key checks
        ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")
        puts "🔗 Foreign key constraints re-enabled"
      end # transaction

    rescue => e
      puts "❌ Migration failed: #{e.message}"
      puts "🔄 Transaction rolled back"
      exit 1
    ensure
      pg_connection&.close
      puts "🔌 PostgreSQL connection closed"
    end

    desc "Create backup of current SQLite database before migration"
    task backup_sqlite: :environment do
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      storage_path = Rails.root.join("storage")
      backup_path = Rails.root.join("backups")

      FileUtils.mkdir_p(backup_path)

      puts "💾 Creating SQLite backup..."

      # Backup all SQLite database files
      %w[production.sqlite3 production_cache.sqlite3 production_queue.sqlite3 production_cable.sqlite3].each do |db_file|
        source = storage_path.join(db_file)
        if source.exist?
          destination = backup_path.join("#{timestamp}_#{db_file}")
          FileUtils.cp(source, destination)
          puts "   ✅ Backed up #{db_file} to #{destination}"
        else
          puts "   ⏩ #{db_file} not found, skipping"
        end
      end

      puts "💾 Backup completed at: #{backup_path}"
    end

    desc "Restore SQLite database from backup"
    task :restore_sqlite, [ :timestamp ] => :environment do |t, args|
      timestamp = args[:timestamp]

      if timestamp.blank?
        puts "❌ Please provide a timestamp: rails db:migrate:restore_sqlite[YYYYMMDD_HHMMSS]"
        exit 1
      end

      storage_path = Rails.root.join("storage")
      backup_path = Rails.root.join("backups")

      puts "🔄 Restoring SQLite backup from #{timestamp}..."

      # Restore all SQLite database files
      %w[production.sqlite3 production_cache.sqlite3 production_queue.sqlite3 production_cable.sqlite3].each do |db_file|
        backup_file = backup_path.join("#{timestamp}_#{db_file}")
        if backup_file.exist?
          destination = storage_path.join(db_file)
          FileUtils.cp(backup_file, destination)
          puts "   ✅ Restored #{db_file}"
        else
          puts "   ⚠️  Backup file not found: #{backup_file}"
        end
      end

      puts "🔄 Restore completed"
    end

    desc "Test the postgres_to_sqlite migration logic using local fixture data"
    task test_migration: :environment do
      puts "🧪 Testing PostgreSQL to SQLite migration logic with local data..."

      # Ensure we're not in production
      if Rails.env.production?
        puts "❌ This test task should not be run in production"
        exit 1
      end

      # Prepare test database with fixtures
      puts "📋 Loading test fixtures..."
      Rake::Task["db:test:prepare"].invoke
      Rake::Task["db:fixtures:load"].invoke("RAILS_ENV=test")

      # Connect to the test database as our "source"
      test_config = ActiveRecord::Base.configurations.find_db_config("test")
      source_db_path = test_config.database

      unless File.exist?(source_db_path)
        puts "❌ Test database not found at #{source_db_path}"
        puts "   Run: bin/rails db:test:prepare"
        exit 1
      end

      # Create a temporary destination database
      dest_db_path = "storage/test_migration_destination.sqlite3"
      FileUtils.rm_f(dest_db_path)

      puts "🔄 Starting test migration..."
      puts "📊 Source: #{source_db_path}"
      puts "📊 Destination: #{dest_db_path}"

      # Connect to source database directly via SQLite3
      source_db = SQLite3::Database.new(source_db_path)

      # Get list of all tables from source
      tables_query = <<~SQL
        SELECT name FROM sqlite_master
        WHERE type='table'
        AND name NOT IN ('ar_internal_metadata', 'schema_migrations', 'sqlite_sequence')
        ORDER BY name;
      SQL

      all_tables = source_db.execute(tables_query).flatten

      # Use the same dependency order as the production migration
      table_order = [
        # Base tables with no foreign key dependencies
        "accounts",
        "seasons",
        "performance_classes",

        # Tables depending on accounts/seasons/performance_classes
        "users",
        "school_classes",
        "schools",
        "contests",

        # Tables depending on schools/users
        "school_directors",
        "large_ensembles",
        "roles",
        "user_roles",

        # Tables depending on contests/users/large_ensembles
        "contest_managers",
        "contest_entries",
        "contests_school_classes",
        "large_ensemble_conductors",
        "rooms",

        # Tables depending on contest_entries/contests/rooms
        "music_selections",
        "performance_phases",
        "schedules",

        # Tables depending on schedules/performance_phases
        "schedule_days",
        "schedule_blocks",

        # Session table (likely no dependencies)
        "sessions"
      ]

      # Only migrate tables that actually exist
      source_tables = table_order.select { |table| all_tables.include?(table) }
      missing_tables = all_tables - table_order
      if missing_tables.any?
        puts "⚠️  Warning: Tables not in migration order: #{missing_tables.join(', ')}"
        source_tables += missing_tables
      end

      puts "📋 Found #{source_tables.length} tables to migrate: #{source_tables.join(', ')}"

      # Create destination database and copy schema
      dest_db = SQLite3::Database.new(dest_db_path)

      # Copy schema by getting the CREATE TABLE statements
      source_tables.each do |table_name|
        schema_sql = source_db.execute("SELECT sql FROM sqlite_master WHERE type='table' AND name=?", [ table_name ]).first
        if schema_sql
          dest_db.execute(schema_sql[0])
          puts "📋 Created table schema: #{table_name}"
        end
      end

      # Start transaction for destination database
      dest_db.transaction do
        # Temporarily disable foreign key checks
        dest_db.execute("PRAGMA foreign_keys = OFF")
        migrated_records = 0

        source_tables.each do |table_name|
          puts "📦 Migrating table: #{table_name}"

          # Get data from source (handle tables without id column)
          begin
            source_data = source_db.execute("SELECT * FROM #{table_name} ORDER BY id")
          rescue SQLite3::SQLException => e
            if e.message.include?("no such column: id")
              # Table doesn't have an id column, just get all data
              source_data = source_db.execute("SELECT * FROM #{table_name}")
            else
              raise e
            end
          end
          record_count = source_data.length

          if record_count == 0
            puts "   ⏩ Empty table, skipping"
            next
          end

          # Get column names
          column_info = source_db.execute("PRAGMA table_info(#{table_name})")
          column_names = column_info.map { |col| col[1] } # col[1] is the column name

          # Clear existing destination table data
          dest_db.execute("DELETE FROM #{table_name}")

          # Insert data into destination
          source_data.each_with_index do |row, index|
            values = row.map do |value|
              case value
              when nil
                "NULL"
              when String
                "'#{value.gsub("'", "''")}'"  # Escape single quotes
              when Time, Date
                "'#{value}'"
              else
                value
              end
            end

            insert_sql = "INSERT INTO #{table_name} (#{column_names.join(', ')}) VALUES (#{values.join(', ')})"

            begin
              dest_db.execute(insert_sql)
            rescue => e
              puts "   ❌ Error inserting record #{index + 1}: #{e.message}"
              puts "   SQL: #{insert_sql}"
              raise e
            end

            # Progress indicator
            if (index + 1) % 100 == 0 || (index + 1) == record_count
              puts "   📈 Progress: #{index + 1}/#{record_count} records"
            end
          end

          migrated_records += record_count
          puts "   ✅ Migrated #{record_count} records from #{table_name}"
        end

        puts "🎉 Test migration completed successfully!"
        puts "📊 Total records migrated: #{migrated_records}"

        # Verify data integrity
        puts "🔍 Verifying data integrity..."
        verification_results = {}

        source_tables.each do |table_name|
          source_count = source_db.execute("SELECT COUNT(*) FROM #{table_name}").first.first
          dest_count = dest_db.execute("SELECT COUNT(*) FROM #{table_name}").first.first

          verification_results[table_name] = {
            source: source_count,
            destination: dest_count,
            match: source_count == dest_count
          }
        end

        # Display verification results
        puts "\n📋 Data Verification Results:"
        verification_results.each do |table, counts|
          status = counts[:match] ? "✅" : "❌"
          puts "   #{status} #{table}: Source=#{counts[:source]}, Destination=#{counts[:destination]}"
        end

        # Check if all verifications passed
        all_match = verification_results.values.all? { |counts| counts[:match] }

        if all_match
          puts "\n🎉 All data verification checks passed!"
          puts "📄 Test database created at: #{dest_db_path}"
        else
          puts "\n❌ Some verification checks failed."
          raise "Data verification failed"
        end

        # Re-enable foreign key checks
        dest_db.execute("PRAGMA foreign_keys = ON")
        puts "🔗 Foreign key constraints re-enabled"
      end

    rescue => e
      puts "❌ Test migration failed: #{e.message}"
      puts "🔄 Transaction rolled back"
      exit 1
    ensure
      source_db&.close
      dest_db&.close
      puts "🔌 Database connections closed"
    end
  end
end
