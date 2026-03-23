class PortfolioController < ApplicationController
  before_action :authenticate_user!

  def show
    @holdings = current_user.portfolio_holdings.by_risk
    @risky_count = @holdings.risky.count
    @total_value = @holdings.sum(:value_usd)
  end

  def scan_wallet
    address = params[:wallet_address]&.strip
    unless address&.match?(/\A[1-9A-HJ-NP-Za-km-z]{32,44}\z/)
      redirect_to portfolio_path, alert: "Invalid Solana wallet address."
      return
    end

    PortfolioScanJob.perform_later(current_user.id, address)
    redirect_to portfolio_path, notice: "Scanning wallet #{address[0..8]}... Results will appear shortly."
  end
end
