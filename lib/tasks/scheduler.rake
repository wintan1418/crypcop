namespace :scheduler do
  desc "Run token discovery (call every 15-30 seconds via cron or process manager)"
  task discover: :environment do
    TokenDiscoveryJob.perform_now
  end

  desc "Run whale wallet monitoring (call every 15-30 seconds)"
  task whales: :environment do
    WhaleMonitorJob.perform_now
  end

  desc "Update token prices (call every 60 seconds)"
  task prices: :environment do
    TokenPriceUpdateJob.perform_now
  end

  desc "Reset daily scan counts (call once per day at midnight)"
  task daily_reset: :environment do
    DailyScanResetJob.perform_now
  end

  desc "Run all periodic tasks once (useful for testing)"
  task all: :environment do
    puts "Running token discovery..."
    TokenDiscoveryJob.perform_now
    puts "Running whale monitor..."
    WhaleMonitorJob.perform_now
    puts "Running price updates..."
    TokenPriceUpdateJob.perform_now
    puts "Done."
  end
end
