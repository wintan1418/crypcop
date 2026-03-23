module Wallets
  class TrackerService
    def initialize(tracked_wallet)
      @wallet = tracked_wallet
      @helius = Solana::HeliusService.new
      @dexscreener = Solana::DexscreenerService.new
    end

    def fetch_recent_transactions!
      result = @helius.get_parsed_transactions(@wallet.wallet_address, limit: 20)
      return [] unless result.is_a?(Array)

      new_txs = []
      result.each do |tx|
        next if WalletTransaction.exists?(tx_signature: tx["signature"])

        parsed = parse_transaction(tx)
        next unless parsed

        wallet_tx = @wallet.wallet_transactions.create!(
          tx_signature: tx["signature"],
          tx_type: parsed[:type],
          amount: parsed[:amount],
          price_usd: parsed[:price_usd],
          value_usd: parsed[:value_usd],
          token_symbol: parsed[:token_symbol],
          token_mint_address: parsed[:token_mint],
          token: Token.find_by(mint_address: parsed[:token_mint]),
          transacted_at: tx["timestamp"] ? Time.at(tx["timestamp"]) : Time.current
        )

        new_txs << wallet_tx
      rescue ActiveRecord::RecordNotUnique
        next
      end

      @wallet.update!(last_activity_at: Time.current) if new_txs.any?
      new_txs
    end

    private

    def parse_transaction(tx)
      # Parse Helius enhanced transaction format
      token_transfers = tx["tokenTransfers"] || []
      return nil if token_transfers.empty?

      transfer = token_transfers.first
      mint = transfer["mint"]
      amount = transfer["tokenAmount"]&.to_f

      is_incoming = transfer["toUserAccount"] == @wallet.wallet_address
      type = is_incoming ? :buy : :sell

      {
        type: type,
        amount: amount,
        token_mint: mint,
        token_symbol: transfer["tokenStandard"],
        price_usd: nil,
        value_usd: nil
      }
    end
  end
end
