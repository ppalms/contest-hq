class BackupCleanupJob < ApplicationJob
  queue_as :default

  def perform
    return unless Rails.env.production?

    s3_client = Rails.application.config.backup.s3_client
    s3_bucket = Rails.application.config.backup.s3_bucket
    retention_days = Rails.application.config.backup.retention_days

    return unless s3_client && s3_bucket

    cutoff_date = retention_days.days.ago

    Rails.logger.info "Cleaning up backups older than #{cutoff_date}"

    deleted_count = 0
    s3_client.list_objects_v2(bucket: s3_bucket, prefix: "backups/").each do |response|
      response.contents.each do |object|
        timestamp = extract_timestamp(object.key)
        next unless timestamp

        object_date = parse_timestamp(timestamp)
        next unless object_date && object_date < cutoff_date

        Rails.logger.info "Deleting old backup: #{object.key}"
        s3_client.delete_object(bucket: s3_bucket, key: object.key)
        deleted_count += 1
      end
    end

    Rails.logger.info "Cleanup completed: #{deleted_count} backups deleted"
  rescue => e
    Rails.logger.error "Backup cleanup failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  private

  def extract_timestamp(key)
    match = key.match(%r{backups/(\d{8}_\d{6})/})
    match[1] if match
  end

  def parse_timestamp(timestamp)
    Time.strptime(timestamp, "%Y%m%d_%H%M%S")
  rescue ArgumentError
    nil
  end
end
