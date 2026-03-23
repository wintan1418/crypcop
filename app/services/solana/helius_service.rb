module Solana
  class HeliusService
    API_BASE = "https://api.helius.xyz"
    RPC_BASE = "https://mainnet.helius-rpc.com"

    def initialize(api_key: nil)
      @api_key = api_key || Rails.application.credentials.dig(:helius, :api_key) || ENV["HELIUS_API_KEY"]
      @client = Client.new
    end

    # Fetch token metadata via DAS (Digital Asset Standard)
    def get_asset(mint_address)
      response = @client.post(
        "#{RPC_BASE}/?api-key=#{@api_key}",
        body: {
          jsonrpc: "2.0",
          id: "crypcop-#{mint_address}",
          method: "getAsset",
          params: { id: mint_address }
        }
      )
      response["result"]
    end

    # Fetch token holder accounts
    def get_token_accounts(mint_address, limit: 20)
      response = @client.post(
        "#{RPC_BASE}/?api-key=#{@api_key}",
        body: {
          jsonrpc: "2.0",
          id: "crypcop-holders-#{mint_address}",
          method: "getTokenAccounts",
          params: {
            mint: mint_address,
            limit: limit,
            showZeroBalance: false
          }
        }
      )
      response["result"]
    end

    # Fetch token supply
    def get_token_supply(mint_address)
      response = @client.post(
        "#{RPC_BASE}/?api-key=#{@api_key}",
        body: {
          jsonrpc: "2.0",
          id: "crypcop-supply-#{mint_address}",
          method: "getTokenSupply",
          params: [ mint_address ]
        }
      )
      response.dig("result", "value")
    end

    # Fetch parsed transaction history for a wallet
    def get_parsed_transactions(wallet_address, limit: 20)
      @client.post(
        "#{API_BASE}/v0/addresses/#{wallet_address}/transactions?api-key=#{@api_key}&limit=#{limit}",
        body: {}
      )
    rescue Client::ApiError => e
      Rails.logger.warn "[Helius] Failed to fetch transactions for #{wallet_address}: #{e.message}"
      []
    end

    # Fetch recent token creation events
    def get_recent_token_creations(limit: 50)
      @client.get(
        "#{API_BASE}/v0/token-metadata?api-key=#{@api_key}&limit=#{limit}&type=fungible"
      )
    rescue Client::ApiError
      # Fallback: return empty if this endpoint isn't available
      []
    end
  end
end
