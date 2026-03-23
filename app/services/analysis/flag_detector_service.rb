module Analysis
  class FlagDetectorService
    def initialize(token)
      @token = token
    end

    def detect
      flags = []

      flags << honeypot_flag if honeypot_risk?
      flags << mint_authority_flag unless @token.mint_authority_revoked?
      flags << freeze_authority_flag unless @token.freeze_authority_revoked?
      flags << concentration_flag if concentrated_holders?
      flags << low_liquidity_flag if low_liquidity?
      flags << unlocked_lp_flag unless @token.lp_locked?
      flags << mutable_flag if @token.is_mutable?
      flags << new_token_flag if very_new?
      flags << low_holders_flag if low_holders?

      flags.compact
    end

    private

    def honeypot_risk?
      !@token.mint_authority_revoked? && !@token.freeze_authority_revoked? && low_liquidity?
    end

    def concentrated_holders?
      @token.top_10_holder_pct.present? && @token.top_10_holder_pct > 50
    end

    def low_liquidity?
      @token.liquidity_usd.present? && @token.liquidity_usd < 5000
    end

    def very_new?
      @token.created_on_chain_at.present? && @token.created_on_chain_at > 1.hour.ago
    end

    def low_holders?
      @token.holder_count.present? && @token.holder_count < 10
    end

    def honeypot_flag
      { type: "honeypot", severity: "critical", message: "Potential honeypot — mint and freeze authorities active with low liquidity" }
    end

    def mint_authority_flag
      { type: "mint_authority", severity: "high", message: "Mint authority not revoked" }
    end

    def freeze_authority_flag
      { type: "freeze_authority", severity: "high", message: "Freeze authority active" }
    end

    def concentration_flag
      { type: "concentration", severity: "high", message: "Top 10 holders own #{@token.top_10_holder_pct}%" }
    end

    def low_liquidity_flag
      { type: "low_liquidity", severity: "medium", message: "Liquidity below $5,000" }
    end

    def unlocked_lp_flag
      { type: "unlocked_lp", severity: "medium", message: "Liquidity pool not locked" }
    end

    def mutable_flag
      { type: "mutable", severity: "low", message: "Token metadata is mutable" }
    end

    def new_token_flag
      { type: "new_token", severity: "low", message: "Token less than 1 hour old" }
    end

    def low_holders_flag
      { type: "low_holders", severity: "low", message: "Fewer than 10 holders" }
    end
  end
end
