module Solana
  class DexscreenerService
    API_BASE = "https://api.dexscreener.com"

    def initialize
      @client = Client.new
    end

    # Fetch latest token profiles (new tokens)
    def latest_token_profiles
      @client.get("#{API_BASE}/token-profiles/latest/v1")
    rescue Client::ApiError => e
      Rails.logger.warn "[DexScreener] Failed to fetch latest profiles: #{e.message}"
      []
    end

    # Fetch pair data for a specific token
    def get_pairs(mint_address)
      response = @client.get("#{API_BASE}/tokens/v1/solana/#{mint_address}")
      return [] unless response.is_a?(Array)
      response
    rescue Client::ApiError => e
      Rails.logger.warn "[DexScreener] Failed to fetch pairs for #{mint_address}: #{e.message}"
      []
    end

    # Search for tokens by query
    def search(query)
      response = @client.get("#{API_BASE}/latest/dex/search?q=#{CGI.escape(query)}")
      response["pairs"] || []
    rescue Client::ApiError
      []
    end

    # Get latest boosted tokens (trending)
    def latest_boosted
      @client.get("#{API_BASE}/token-boosts/latest/v1")
    rescue Client::ApiError
      []
    end
  end
end
