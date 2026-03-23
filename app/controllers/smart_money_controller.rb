class SmartMoneyController < ApplicationController
  def index
    @smart_wallets = TrackedWallet.smart_money.recent_activity.limit(20)
    @recent_transactions = WalletTransaction.joins(:tracked_wallet)
      .where(tracked_wallets: { is_smart_money: true })
      .recent.limit(50)
      .includes(:tracked_wallet, :token)
  end
end
