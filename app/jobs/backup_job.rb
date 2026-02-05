class BackupJob < ApplicationJob
  queue_as :default

  def perform
    BackupService.new.perform
  end
end
