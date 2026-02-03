require "aws-sdk-s3"

Rails.application.configure do
  config.backup = ActiveSupport::OrderedOptions.new

  if Rails.env.production? && Rails.application.credentials.backup.present?
    backup_config = Rails.application.credentials.backup

    config.backup.s3_client = Aws::S3::Client.new(
      access_key_id: backup_config[:s3_access_key_id],
      secret_access_key: backup_config[:s3_secret_access_key],
      region: backup_config[:s3_region] || "auto",
      endpoint: backup_config[:s3_endpoint],
      force_path_style: true
    )

    config.backup.s3_bucket = backup_config[:s3_bucket]
    config.backup.retention_days = 30
  else
    config.backup.s3_client = nil
    config.backup.s3_bucket = nil
    config.backup.retention_days = 30
  end
end
