class TrackedWalletsController < ApplicationController
  before_action :authenticate_user!

  def index
    @tracked_wallets = current_user.tracked_wallets.recent_activity
  end

  def show
    @wallet = current_user.tracked_wallets.find(params[:id])
    @transactions = @wallet.wallet_transactions.recent.limit(50)
  end

  def create
    @wallet = current_user.tracked_wallets.build(tracked_wallet_params)

    if @wallet.save
      WalletTrackJob.perform_later(@wallet.id)
      redirect_to tracked_wallet_path(@wallet), notice: "Wallet added! Fetching transactions..."
    else
      redirect_to tracked_wallets_path, alert: @wallet.errors.full_messages.join(", ")
    end
  end

  def destroy
    wallet = current_user.tracked_wallets.find(params[:id])
    wallet.destroy!
    redirect_to tracked_wallets_path, notice: "Wallet removed."
  end

  def refresh
    @wallet = current_user.tracked_wallets.find(params[:id])
    WalletTrackJob.perform_later(@wallet.id)
    redirect_to tracked_wallet_path(@wallet), notice: "Refreshing transactions..."
  end

  private

  def tracked_wallet_params
    params.require(:tracked_wallet).permit(:wallet_address, :label, :notify_on_buy, :notify_on_sell)
  end
end
