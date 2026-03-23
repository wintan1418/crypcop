class PortfolioScanJob < ApplicationJob
  queue_as :default

  def perform(user_id, wallet_address)
    user = User.find(user_id)
    Wallets::PortfolioScannerService.new(user, wallet_address).scan!
  end
end
