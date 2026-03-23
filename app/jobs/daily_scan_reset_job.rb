class DailyScanResetJob < ApplicationJob
  queue_as :default

  def perform
    User.where("daily_scan_count > 0").update_all(
      daily_scan_count: 0,
      daily_scan_reset_at: Time.current
    )
    Rails.logger.info "[DailyScanReset] Reset scan counts for all users"
  end
end
