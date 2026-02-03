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

    backup_database
    upload_to_s3
    cleanup_local_backup

    Rails.logger.info "Backup completed successfully: #{backup_key}"
  rescue => e
    Rails.logger.error "Backup failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    cleanup_local_backup
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

  def backup_database
    Rails.logger.info "Creating database backup: #{local_backup_path}"

    ActiveRecord::Base.connection.execute(
      "VACUUM INTO '#{local_backup_path}'"
    )

    Rails.logger.info "Database backup created: #{File.size(local_backup_path)} bytes"
  end

  def upload_to_s3
    Rails.logger.info "Uploading to S3: #{backup_key}"

    File.open(local_backup_path, "rb") do |file|
      s3_client.put_object(
        bucket: s3_bucket,
        key: backup_key,
        body: file,
        metadata: {
          "timestamp" => timestamp,
          "size" => File.size(local_backup_path).to_s,
          "rails_env" => Rails.env
        }
      )
    end

    Rails.logger.info "Upload completed: #{backup_key}"
  end

  def cleanup_local_backup
    return unless File.exist?(local_backup_path)

    File.delete(local_backup_path)
    Rails.logger.info "Local backup file deleted: #{local_backup_path}"
  end

  def local_backup_path
    @local_backup_path ||= Rails.root.join("tmp", "backup_#{timestamp}.sqlite3")
  end

  def backup_key
    @backup_key ||= "backups/#{timestamp}/production.sqlite3"
  end
end
