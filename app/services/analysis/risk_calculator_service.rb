module Analysis
  class RiskCalculatorService
    RISK_LEVELS = {
      0..20 => :safe,
      21..40 => :low,
      41..60 => :medium,
      61..80 => :high,
      81..100 => :critical
    }.freeze

    def initialize(token)
      @token = token
    end

    def calculate
      score = 0
      flags = []

      # Mint authority not revoked: +30
      unless @token.mint_authority_revoked?
        score += 30
        flags << "Mint authority is NOT revoked — creator can mint unlimited tokens"
      end

      # Freeze authority not revoked: +15
      unless @token.freeze_authority_revoked?
        score += 15
        flags << "Freeze authority is active — creator can freeze token transfers"
      end

      # Top 10 holders own >50%: +20
      if @token.top_10_holder_pct.present? && @token.top_10_holder_pct > 50
        score += 20
        flags << "Top 10 holders own #{@token.top_10_holder_pct}% of supply — high concentration risk"
      elsif @token.top_10_holder_pct.present? && @token.top_10_holder_pct > 30
        score += 10
        flags << "Top 10 holders own #{@token.top_10_holder_pct}% of supply — moderate concentration"
      end

      # Low liquidity: +15
      if @token.liquidity_usd.present? && @token.liquidity_usd < 5000
        score += 15
        flags << "Very low liquidity ($#{@token.liquidity_usd.to_i}) — high slippage and exit risk"
      elsif @token.liquidity_usd.present? && @token.liquidity_usd < 20000
        score += 8
        flags << "Low liquidity ($#{@token.liquidity_usd.to_i}) — moderate exit risk"
      end

      # LP not locked: +10
      unless @token.lp_locked?
        score += 10
        flags << "Liquidity pool is NOT locked — creator can remove liquidity at any time"
      end

      # Metadata is mutable: +5
      if @token.is_mutable?
        score += 5
        flags << "Token metadata is mutable — name/symbol/image can be changed"
      end

      # Very new token (< 1 hour): +5
      if @token.created_on_chain_at.present? && @token.created_on_chain_at > 1.hour.ago
        score += 5
        flags << "Token is less than 1 hour old — extremely new"
      end

      # No holders data: +5
      if @token.holder_count.nil? || @token.holder_count < 10
        score += 5
        flags << "Very few holders (#{@token.holder_count || 0}) — limited adoption"
      end

      score = [ score, 100 ].min
      risk_level = determine_level(score)

      {
        risk_score: score,
        risk_level: risk_level,
        flags: flags,
        summary: generate_summary(score, risk_level, flags)
      }
    end

    private

    def determine_level(score)
      RISK_LEVELS.find { |range, _| range.include?(score) }&.last || :safe
    end

    def generate_summary(score, level, flags)
      case level
      when :safe
        "This token shows low risk indicators. Key safety features like revoked mint authority and locked liquidity are in place."
      when :low
        "This token has some minor risk factors. #{flags.first}. Overall risk is manageable but monitor for changes."
      when :medium
        "This token shows moderate risk. #{flags.size} potential issues detected including: #{flags.first(2).join('; ')}. Exercise caution."
      when :high
        "HIGH RISK: This token has multiple red flags. #{flags.first(3).join('. ')}. Investing carries significant risk of loss."
      when :critical
        "CRITICAL RISK: This token has severe red flags suggesting a potential rug pull. #{flags.first(3).join('. ')}. Strongly advise against investing."
      end
    end
  end
end
