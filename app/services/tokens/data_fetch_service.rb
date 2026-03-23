module Tokens
  class DataFetchService
    def initialize(token)
      @token = token
      @helius = Solana::HeliusService.new
      @dexscreener = Solana::DexscreenerService.new
      @jupiter = Solana::JupiterService.new
    end

    def fetch!
      fetch_dexscreener_data
      fetch_helius_metadata
      fetch_holder_data
      fetch_price_data

      @token.data_fetched_at = Time.current
      @token.save!

      @token
    end

    private

    def fetch_dexscreener_data
      pairs = @dexscreener.get_pairs(@token.mint_address)
      return if pairs.empty?

      # Use the first/primary pair
      pair = pairs.first
      base_token = pair["baseToken"] || {}
      info = pair["info"] || {}

      @token.name = base_token["name"] if @token.name.blank? && base_token["name"].present?
      @token.symbol = base_token["symbol"] if base_token["symbol"].present?

      @token.latest_price_usd = pair["priceUsd"]&.to_f
      @token.market_cap_usd = pair.dig("marketCap")&.to_f || pair.dig("fdv")&.to_f
      @token.liquidity_usd = pair.dig("liquidity", "usd")&.to_f
      @token.volume_24h_usd = pair.dig("volume", "h24")&.to_f

      if pair["pairCreatedAt"]
        @token.dex_listed_at = Time.at(pair["pairCreatedAt"].to_i / 1000) rescue nil
        @token.created_on_chain_at ||= @token.dex_listed_at
      end

      @token.image_url = info.dig("imageUrl") if info.dig("imageUrl").present?
    rescue => e
      Rails.logger.warn "[DataFetch] DexScreener error for #{@token.mint_address}: #{e.message}"
    end

    def fetch_helius_metadata
      asset = @helius.get_asset(@token.mint_address)
      return unless asset

      content = asset["content"] || {}
      metadata = content.dig("metadata") || {}
      authorities = asset["authorities"] || []
      ownership = asset["ownership"] || {}

      @token.name = metadata["name"] if @token.name.blank? && metadata["name"].present?
      @token.symbol = metadata["symbol"] if @token.symbol.blank? && metadata["symbol"].present?
      @token.description = metadata["description"] if metadata["description"].present?
      @token.decimals = asset.dig("token_info", "decimals")
      @token.supply = asset.dig("token_info", "supply")

      # Check authorities
      @token.creator_address = ownership["owner"]
      @token.is_mutable = asset["mutable"] || false

      # Mint authority
      mint_auth = asset.dig("token_info", "mint_authority")
      @token.mint_authority = mint_auth
      @token.mint_authority_revoked = mint_auth.nil? || mint_auth.empty?

      # Freeze authority
      freeze_auth = asset.dig("token_info", "freeze_authority")
      @token.freeze_authority = freeze_auth
      @token.freeze_authority_revoked = freeze_auth.nil? || freeze_auth.empty?

      # Image
      links = content["links"] || {}
      image = content.dig("files", 0, "uri") || links["image"]
      @token.image_url = image if image.present? && @token.image_url.blank?
    rescue => e
      Rails.logger.warn "[DataFetch] Helius metadata error for #{@token.mint_address}: #{e.message}"
    end

    def fetch_holder_data
      result = @helius.get_token_accounts(@token.mint_address, limit: 20)
      return unless result

      accounts = result["token_accounts"] || []
      return if accounts.empty?

      total_held = accounts.sum { |a| a["amount"]&.to_f || 0 }
      supply = @token.supply&.to_f

      if supply && supply > 0
        top_10 = accounts.first(10).sum { |a| a["amount"]&.to_f || 0 }
        @token.top_10_holder_pct = (top_10 / supply * 100).round(2)
      end

      @token.holder_count = accounts.size
    rescue => e
      Rails.logger.warn "[DataFetch] Helius holder error for #{@token.mint_address}: #{e.message}"
    end

    def fetch_price_data
      price_data = @jupiter.get_price(@token.mint_address)
      return unless price_data

      @token.latest_price_usd = price_data[:price_usd] if price_data[:price_usd]
    rescue => e
      Rails.logger.warn "[DataFetch] Jupiter price error for #{@token.mint_address}: #{e.message}"
    end
  end
end
