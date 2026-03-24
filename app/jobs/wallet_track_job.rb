class WalletTrackJob < ApplicationJob
  queue_as :default

  def perform(tracked_wallet_id)
    wallet = TrackedWallet.find(tracked_wallet_id)
    service = Wallets::TrackerService.new(wallet)
    new_txs = service.fetch_recent_transactions!

    # Send Telegram alerts for new transactions
    bot = TgBot::BotService.new
    new_txs.each do |tx|
      if (tx.buy? && wallet.notify_on_buy?) || (tx.sell? && wallet.notify_on_sell?)
        bot.send_wallet_alert(wallet.user, wallet, tx)
      end
    end
  end
end
