class BackupService
  attr_reader :timestamp, :s3_client, :s3_bucket

  def initialize
    @timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    @s3_client = Rails.application.config.backup.s3_client
    @s3_bucket = Rails.application.config.backup.s3_bucket
  end

  def perform
    return unless production_environment?

    Rails.logger.info "Starting backup at #{timestamp}"

    backup_all_databases
    upload_to_s3
    cleanup_local_backups

    Rails.logger.info "Backup completed successfully"
  rescue => e
    Rails.logger.error "Backup failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    cleanup_local_backups
    raise
  end

  private

  def production_environment?
    unless Rails.env.production?
      Rails.logger.warn "Backups only run in production environment"
      return false
    end

    unless s3_client && s3_bucket
      Rails.logger.error "Backup not configured. Check credentials."
      return false
    end

    true
  end

  def backup_all_databases
    databases.each do |db_name, db_config|
      backup_database(db_name, db_config)
    end
  end

  def backup_database(db_name, db_config)
    db_path = Rails.root.join(db_config["database"])
    backup_path = local_backup_path(db_name)

    Rails.logger.info "Backing up #{db_name} database: #{db_path}"

    # Connect to the specific database and create backup
    # Note: VACUUM INTO doesn't support parameterized queries in SQLite
    # backup_path is sanitized and controlled by the application
    ActiveRecord::Base.connected_to(role: db_name.to_sym) do
      # Sanitize the path to prevent any potential injection
      sanitized_path = ActiveRecord::Base.connection.quote(backup_path)
      ActiveRecord::Base.connection.execute(
        "VACUUM INTO #{sanitized_path}"
      )
    end

    Rails.logger.info "#{db_name} backup created: #{File.size(backup_path)} bytes"
  end

  def upload_to_s3
    databases.each do |db_name, _db_config|
      backup_path = local_backup_path(db_name)
      s3_key = backup_key(db_name)

      Rails.logger.info "Uploading #{db_name} to S3: #{s3_key}"

      File.open(backup_path, "rb") do |file|
        s3_client.put_object(
          bucket: s3_bucket,
          key: s3_key,
          body: file,
          metadata: {
            "timestamp" => timestamp,
            "database" => db_name,
            "size" => File.size(backup_path).to_s,
            "rails_env" => Rails.env
          }
        )
      end

      Rails.logger.info "Upload completed: #{s3_key}"
    end
  end

  def cleanup_local_backups
    databases.each do |db_name, _db_config|
      backup_path = local_backup_path(db_name)
      next unless File.exist?(backup_path)

      File.delete(backup_path)
      Rails.logger.info "Local backup file deleted: #{backup_path}"
    end
  end

  def databases
    @databases ||= Rails.configuration.database_configuration[Rails.env]
  end

  def local_backup_path(db_name)
    Rails.root.join("tmp", "backup_#{timestamp}_#{db_name}.sqlite3")
  end

  def backup_key(db_name)
    "backups/#{timestamp}/#{db_name}.sqlite3"
  end
end
