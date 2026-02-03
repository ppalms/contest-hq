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

    backups = []
    s3_client.list_objects_v2(bucket: s3_bucket, prefix: "backups/").each do |response|
      response.contents.each do |object|
        timestamp = object.key.match(%r{backups/(\d{8}_\d{6})/})&.captures&.first
        next unless timestamp

        backups << {
          timestamp: timestamp,
          key: object.key,
          size: object.size,
          last_modified: object.last_modified
        }
      end
    end

    if backups.empty?
      puts "No backups found"
    else
      backups.sort_by { |b| b[:timestamp] }.reverse.each do |backup|
        size_mb = (backup[:size] / 1024.0 / 1024.0).round(2)
        puts "#{backup[:timestamp]} - #{size_mb} MB - #{backup[:last_modified]}"
      end
      puts ""
      puts "Total: #{backups.size} backups"
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

    backup_key = "backups/#{args[:timestamp]}/production.sqlite3"
    puts "Verifying backup: #{backup_key}"

    begin
      response = s3_client.head_object(bucket: s3_bucket, key: backup_key)
      size_mb = (response.content_length / 1024.0 / 1024.0).round(2)

      puts "✓ Backup exists"
      puts "  Size: #{size_mb} MB"
      puts "  Last modified: #{response.last_modified}"
      puts "  Metadata: #{response.metadata.inspect}"
      puts ""
      puts "Backup verification successful"
    rescue Aws::S3::Errors::NotFound
      puts "✗ Backup not found: #{backup_key}"
      exit 1
    rescue => e
      puts "✗ Verification failed: #{e.message}"
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

    backup_key = "backups/#{args[:timestamp]}/production.sqlite3"
    db_path = Rails.root.join("storage", "production.sqlite3")
    temp_path = Rails.root.join("tmp", "restore_#{args[:timestamp]}.sqlite3")

    puts "WARNING: This will replace your current database!"
    puts "Current database: #{db_path}"
    puts "Backup to restore: #{backup_key}"
    puts ""
    print "Type 'RESTORE' to confirm: "
    confirmation = $stdin.gets.chomp

    unless confirmation == "RESTORE"
      puts "Restore cancelled"
      exit 0
    end

    begin
      puts "Downloading backup..."
      s3_client.get_object(
        bucket: s3_bucket,
        key: backup_key,
        response_target: temp_path.to_s
      )

      size_mb = (File.size(temp_path) / 1024.0 / 1024.0).round(2)
      puts "Downloaded #{size_mb} MB"

      puts "Creating backup of current database..."
      current_backup = db_path.to_s + ".before_restore"
      FileUtils.cp(db_path, current_backup)
      puts "Current database backed up to: #{current_backup}"

      puts "Replacing database..."
      FileUtils.mv(temp_path, db_path)

      puts ""
      puts "✓ Restore completed successfully"
      puts "  Database restored from: #{backup_key}"
      puts "  Previous database saved to: #{current_backup}"
      puts ""
      puts "IMPORTANT: Restart your application now"
    rescue => e
      puts "✗ Restore failed: #{e.message}"
      FileUtils.rm(temp_path) if File.exist?(temp_path)
      exit 1
    end
  end
end
