module Tokens
  class DiscoveryService
    def initialize
      @dexscreener = Solana::DexscreenerService.new
    end

    def discover!
      profiles = @dexscreener.latest_token_profiles
      return [] unless profiles.is_a?(Array)

      # Filter to Solana tokens only
      solana_profiles = profiles.select { |p| p["chainId"] == "solana" }

      new_tokens = []
      solana_profiles.each do |profile|
        mint_address = profile["tokenAddress"]
        next if mint_address.blank?
        next if Token.exists?(mint_address: mint_address)

        token = Token.create!(
          mint_address: mint_address,
          name: profile["description"]&.truncate(100),
          image_url: profile["icon"],
          created_on_chain_at: Time.current
        )

        # Enqueue data fetch for this token
        TokenDataFetchJob.perform_later(token.id)
        new_tokens << token
      rescue ActiveRecord::RecordNotUnique
        # Another worker already created this token, skip
        next
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn "[Discovery] Failed to create token #{mint_address}: #{e.message}"
        next
      end

      Rails.logger.info "[Discovery] Found #{new_tokens.size} new tokens from #{solana_profiles.size} profiles"
      new_tokens
    end
  end
end
