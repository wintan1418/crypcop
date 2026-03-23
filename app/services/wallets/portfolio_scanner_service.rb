module Wallets
  class PortfolioScannerService
    def initialize(user, wallet_address)
      @user = user
      @wallet_address = wallet_address
      @helius = Solana::HeliusService.new
      @jupiter = Solana::JupiterService.new
    end

    def scan!
      # Fetch all token accounts for this wallet
      accounts = fetch_token_accounts
      return [] if accounts.empty?

      # Clear old holdings for this wallet
      @user.portfolio_holdings.where(wallet_address: @wallet_address).destroy_all

      holdings = []
      mint_addresses = accounts.map { |a| a["mint"] }.compact.uniq

      # Batch fetch prices
      prices = @jupiter.get_prices(mint_addresses.first(100))

      accounts.each do |account|
        mint = account["mint"]
        amount = account["amount"]&.to_f
        next if amount.nil? || amount <= 0

        # Find or fetch token data
        token = Token.find_by(mint_address: mint)
        price = prices.dig(mint, :price_usd) || token&.latest_price_usd
        value_usd = price && amount ? (price * amount) : nil

        # Get risk score
        risk_score = token&.risk_score
        risk_level = token&.risk_level || "safe"

        holding = @user.portfolio_holdings.create!(
          token: token,
          wallet_address: @wallet_address,
          token_mint_address: mint,
          token_symbol: token&.symbol,
          token_name: token&.name,
          amount: amount,
          value_usd: value_usd,
          risk_score: risk_score,
          risk_level: risk_level
        )
        holdings << holding
      end

      holdings
    end

    private

    def fetch_token_accounts
      result = @helius.get_token_accounts(@wallet_address, limit: 100)
      return [] unless result
      result["token_accounts"] || []
    rescue => e
      Rails.logger.warn "[PortfolioScanner] Error fetching accounts: #{e.message}"
      []
    end
  end
end
