module Tokens
  class PriceUpdateService
    def initialize
      @jupiter = Solana::JupiterService.new
    end

    def update!
      # Get all tokens that are being watched or recently scanned
      token_ids = WatchlistItem.distinct.pluck(:token_id)
      recent_ids = Token.where("last_scanned_at > ?", 24.hours.ago).pluck(:id)
      all_ids = (token_ids + recent_ids).uniq

      return if all_ids.empty?

      tokens = Token.where(id: all_ids)
      mint_addresses = tokens.pluck(:mint_address)

      # Batch fetch prices (Jupiter supports multiple)
      prices = @jupiter.get_prices(mint_addresses)

      tokens.each do |token|
        price_data = prices[token.mint_address]
        next unless price_data && price_data[:price_usd]

        token.update_columns(
          latest_price_usd: price_data[:price_usd],
          updated_at: Time.current
        )
      end

      Rails.logger.info "[PriceUpdate] Updated prices for #{tokens.size} tokens"
    end
  end
end
