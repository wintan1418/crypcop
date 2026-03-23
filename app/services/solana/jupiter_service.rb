module Solana
  class JupiterService
    API_BASE = "https://api.jup.ag"

    def initialize
      @client = Client.new
    end

    # Fetch token price in USD
    def get_price(mint_address)
      response = @client.get("#{API_BASE}/price/v2?ids=#{mint_address}")
      data = response.dig("data", mint_address)
      return nil unless data
      {
        price_usd: data["price"]&.to_f,
        mint_address: mint_address
      }
    rescue Client::ApiError => e
      Rails.logger.warn "[Jupiter] Failed to fetch price for #{mint_address}: #{e.message}"
      nil
    end

    # Fetch prices for multiple tokens
    def get_prices(mint_addresses)
      ids = mint_addresses.join(",")
      response = @client.get("#{API_BASE}/price/v2?ids=#{ids}")
      data = response["data"] || {}
      data.transform_values do |v|
        { price_usd: v["price"]&.to_f }
      end
    rescue Client::ApiError => e
      Rails.logger.warn "[Jupiter] Failed to fetch batch prices: #{e.message}"
      {}
    end
  end
end
