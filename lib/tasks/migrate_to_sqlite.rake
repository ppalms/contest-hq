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
      unless ActiveRecord::Base.connection.adapter_name == 'SQLite'
        puts "❌ Current database is not SQLite. Please ensure database.yml is configured for SQLite."
        exit 1
      end

      puts "📊 Exporting data from PostgreSQL..."

      # PostgreSQL connection details (from environment or secrets)
      pg_config = {
        host: ENV['OLD_DB_HOST'] || '167.71.21.241',
        port: ENV['OLD_POSTGRES_PORT'] || 5432,
        database: ENV['OLD_POSTGRES_DB'] || 'contest_hq_production',
        username: ENV['OLD_POSTGRES_USER'],
        password: ENV['OLD_POSTGRES_PASSWORD']
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
        require 'pg'
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

      pg_tables = pg_connection.exec(tables_query).map { |row| row['table_name'] }
      puts "📋 Found #{pg_tables.length} tables to migrate: #{pg_tables.join(', ')}"

      # Start transaction for SQLite
      ActiveRecord::Base.transaction do
        migrated_records = 0

        pg_tables.each do |table_name|
          puts "📦 Migrating table: #{table_name}"

          # Get data from PostgreSQL
          pg_data = pg_connection.exec("SELECT * FROM #{table_name} ORDER BY id")
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
                'NULL'
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
    task :restore_sqlite, [:timestamp] => :environment do |t, args|
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
  end
end