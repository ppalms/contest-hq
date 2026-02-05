namespace :backup do
  desc "Run backup manually"
  task run: :environment do
    puts "Starting manual backup..."
    BackupService.new.perform
    puts "Backup completed successfully"
  rescue => e
    puts "Backup failed: #{e.message}"
    exit 1
  end

  desc "List available backups"
  task list: :environment do
    s3_client = Rails.application.config.backup.s3_client
    s3_bucket = Rails.application.config.backup.s3_bucket

    unless s3_client && s3_bucket
      puts "Backup not configured"
      exit 1
    end

    puts "Available backups in #{s3_bucket}:"
    puts ""

    backup_sets = {}
    s3_client.list_objects_v2(bucket: s3_bucket, prefix: "backups/").each do |response|
      response.contents.each do |object|
        match = object.key.match(%r{backups/(\d{8}_\d{6})/(\w+)\.sqlite3})
        next unless match

        timestamp = match[1]
        db_name = match[2]

        backup_sets[timestamp] ||= { databases: {}, last_modified: nil }
        backup_sets[timestamp][:databases][db_name] = {
          size: object.size,
          last_modified: object.last_modified
        }
        backup_sets[timestamp][:last_modified] ||= object.last_modified
      end
    end

    if backup_sets.empty?
      puts "No backups found"
    else
      backup_sets.sort_by { |timestamp, _| timestamp }.reverse.each do |timestamp, data|
        total_size = data[:databases].values.sum { |db| db[:size] }
        size_mb = (total_size / 1024.0 / 1024.0).round(2)

        puts "#{timestamp} - #{size_mb} MB - #{data[:last_modified]}"
        data[:databases].each do |db_name, db_data|
          db_size_mb = (db_data[:size] / 1024.0 / 1024.0).round(2)
          puts "  └─ #{db_name}: #{db_size_mb} MB"
        end
        puts ""
      end
      puts "Total: #{backup_sets.size} backup sets"
    end
  end

  desc "Verify backup integrity"
  task :verify, [ :timestamp ] => :environment do |_t, args|
    unless args[:timestamp]
      puts "Usage: rails backup:verify[TIMESTAMP]"
      puts "Example: rails backup:verify[20260203_030000]"
      exit 1
    end

    s3_client = Rails.application.config.backup.s3_client
    s3_bucket = Rails.application.config.backup.s3_bucket

    unless s3_client && s3_bucket
      puts "Backup not configured"
      exit 1
    end

    databases = Rails.configuration.database_configuration[Rails.env]
    puts "Verifying backup set: #{args[:timestamp]}"
    puts ""

    all_valid = true
    total_size = 0

    databases.each do |db_name, _db_config|
      backup_key = "backups/#{args[:timestamp]}/#{db_name}.sqlite3"

      begin
        response = s3_client.head_object(bucket: s3_bucket, key: backup_key)
        size_mb = (response.content_length / 1024.0 / 1024.0).round(2)
        total_size += response.content_length

        puts "✓ #{db_name} database"
        puts "  Size: #{size_mb} MB"
        puts "  Last modified: #{response.last_modified}"
        puts ""
      rescue Aws::S3::Errors::NotFound
        puts "✗ #{db_name} database - NOT FOUND"
        puts "  Expected: #{backup_key}"
        puts ""
        all_valid = false
      rescue => e
        puts "✗ #{db_name} database - ERROR"
        puts "  #{e.message}"
        puts ""
        all_valid = false
      end
    end

    if all_valid
      total_mb = (total_size / 1024.0 / 1024.0).round(2)
      puts "=" * 60
      puts "✓ Backup verification successful"
      puts "  Total size: #{total_mb} MB"
      puts "  All #{databases.size} databases present"
      puts "=" * 60
    else
      puts "=" * 60
      puts "✗ Backup verification failed"
      puts "  Some databases are missing or invalid"
      puts "=" * 60
      exit 1
    end
  end

  desc "Restore from backup (DESTRUCTIVE - stops app and replaces database)"
  task :restore, [ :timestamp ] => :environment do |_t, args|
    unless args[:timestamp]
      puts "Usage: rails backup:restore[TIMESTAMP]"
      puts "Example: rails backup:restore[20260203_030000]"
      exit 1
    end

    unless Rails.env.production?
      puts "ERROR: Restore can only be run in production environment"
      exit 1
    end

    s3_client = Rails.application.config.backup.s3_client
    s3_bucket = Rails.application.config.backup.s3_bucket

    unless s3_client && s3_bucket
      puts "Backup not configured"
      exit 1
    end

    databases = Rails.configuration.database_configuration[Rails.env]

    puts "WARNING: This will replace your current databases!"
    puts "Databases to restore:"
    databases.each do |db_name, db_config|
      puts "  - #{db_name}: #{db_config['database']}"
    end
    puts ""
    puts "Backup timestamp: #{args[:timestamp]}"
    puts ""
    print "Type 'RESTORE' to confirm: "
    confirmation = $stdin.gets.chomp

    unless confirmation == "RESTORE"
      puts "Restore cancelled"
      exit 0
    end

    begin
      restored_databases = []
      backed_up_databases = []

      databases.each do |db_name, db_config|
        backup_key = "backups/#{args[:timestamp]}/#{db_name}.sqlite3"
        db_path = Rails.root.join(db_config["database"])
        temp_path = Rails.root.join("tmp", "restore_#{args[:timestamp]}_#{db_name}.sqlite3")

        puts ""
        puts "Restoring #{db_name} database..."

        # Download backup from S3
        puts "Downloading #{backup_key}..."
        s3_client.get_object(
          bucket: s3_bucket,
          key: backup_key,
          response_target: temp_path.to_s
        )

        size_mb = (File.size(temp_path) / 1024.0 / 1024.0).round(2)
        puts "Downloaded #{size_mb} MB"

        # Backup current database if it exists
        if File.exist?(db_path)
          puts "Creating backup of current #{db_name} database..."
          current_backup = db_path.to_s + ".before_restore"
          FileUtils.cp(db_path, current_backup)
          puts "Current database backed up to: #{current_backup}"
          backed_up_databases << { name: db_name, path: current_backup }
        else
          puts "No existing #{db_name} database found (initial setup)"
        end

        # Ensure directory exists
        FileUtils.mkdir_p(db_path.dirname) unless Dir.exist?(db_path.dirname)

        # Replace database
        puts "Replacing #{db_name} database..."
        FileUtils.mv(temp_path, db_path)

        restored_databases << db_name
        puts "✓ #{db_name} database restored"
      end

      puts ""
      puts "=" * 60
      puts "✓ Restore completed successfully"
      puts "=" * 60
      puts ""
      puts "Restored databases:"
      restored_databases.each do |db_name|
        puts "  ✓ #{db_name}"
      end

      if backed_up_databases.any?
        puts ""
        puts "Previous databases backed up to:"
        backed_up_databases.each do |backup|
          puts "  - #{backup[:name]}: #{backup[:path]}"
        end
      else
        puts ""
        puts "(No previous databases - initial setup)"
      end

      puts ""
      puts "IMPORTANT: Restart your application now"
      puts "  kamal app restart"
    rescue => e
      puts ""
      puts "✗ Restore failed: #{e.message}"
      puts e.backtrace.first(5).join("\n")

      # Cleanup temp files
      databases.each do |db_name, _db_config|
        temp_path = Rails.root.join("tmp", "restore_#{args[:timestamp]}_#{db_name}.sqlite3")
        FileUtils.rm(temp_path) if File.exist?(temp_path)
      end

      exit 1
    end
  end
end
