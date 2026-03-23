require "net/http"
require "json"

module Analysis
  class AiAnalysisService
    API_URL = "https://api.anthropic.com/v1/messages"
    MODEL = "claude-sonnet-4-20250514"

    def initialize(token, scan)
      @token = token
      @scan = scan
      @api_key = Rails.application.credentials.dig(:anthropic, :api_key) || ENV["ANTHROPIC_API_KEY"]
    end

    def analyze!
      unless @api_key.present?
        Rails.logger.warn "[AiAnalysis] No API key — falling back to deterministic scorer"
        return fallback_analysis
      end

      prompt = build_prompt
      response = call_claude(prompt)
      parse_response(response)
    rescue => e
      Rails.logger.error "[AiAnalysis] Claude API error: #{e.message}"
      fallback_analysis
    end

    private

    def build_prompt
      <<~PROMPT
        Analyze this Solana token for rug-pull risk. Return ONLY valid JSON with no other text.

        TOKEN DATA:
        - Name: #{@token.name || "Unknown"}
        - Symbol: #{@token.symbol || "Unknown"}
        - Mint Address: #{@token.mint_address}
        - Created: #{@token.created_on_chain_at || "Unknown"}
        - Price USD: #{@token.latest_price_usd || "Unknown"}
        - Market Cap: $#{@token.market_cap_usd || "Unknown"}
        - Liquidity: $#{@token.liquidity_usd || "Unknown"}
        - 24h Volume: $#{@token.volume_24h_usd || "Unknown"}
        - Holder Count: #{@token.holder_count || "Unknown"}
        - Top 10 Holders Own: #{@token.top_10_holder_pct || "Unknown"}%
        - Mint Authority Revoked: #{@token.mint_authority_revoked?}
        - Freeze Authority Revoked: #{@token.freeze_authority_revoked?}
        - LP Locked: #{@token.lp_locked? || "Unknown"}
        - Metadata Mutable: #{@token.is_mutable?}
        - Supply: #{@token.supply || "Unknown"}

        SCORING RUBRIC:
        - Mint authority NOT revoked: +30 points
        - Freeze authority NOT revoked: +15 points
        - Top 10 holders own >50%: +20 points
        - Liquidity < $5,000: +15 points
        - LP not locked: +10 points
        - Metadata mutable: +5 points
        - Token < 1 hour old: +5 points
        - < 10 holders: +5 points

        Score bands: 0-20 safe, 21-40 low, 41-60 medium, 61-80 high, 81-100 critical.

        Return JSON:
        {
          "risk_score": <0-100>,
          "risk_level": "<safe|low|medium|high|critical>",
          "summary": "<2-3 sentence plain English explanation for a crypto trader>",
          "flags": ["<specific red flag 1>", "<specific red flag 2>", ...],
          "detailed_analysis": {
            "authority_risk": "<assessment>",
            "liquidity_risk": "<assessment>",
            "holder_risk": "<assessment>",
            "overall": "<assessment>"
          }
        }
      PROMPT
    end

    def call_claude(prompt)
      uri = URI(API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["x-api-key"] = @api_key
      request["anthropic-version"] = "2023-06-01"

      request.body = {
        model: MODEL,
        max_tokens: 1024,
        messages: [
          {
            role: "user",
            content: prompt
          }
        ],
        system: "You are a crypto security analyst specializing in Solana token rug-pull detection. You analyze on-chain data and return structured risk assessments. Always return valid JSON only, no markdown formatting."
      }.to_json

      response = http.request(request)

      unless response.code.to_i == 200
        raise "Claude API returned #{response.code}: #{response.body.to_s[0..200]}"
      end

      body = JSON.parse(response.body)
      content = body.dig("content", 0, "text")
      raise "Empty response from Claude" if content.blank?

      JSON.parse(content)
    end

    def parse_response(data)
      {
        risk_score: data["risk_score"].to_i.clamp(0, 100),
        risk_level: validate_level(data["risk_level"]),
        summary: data["summary"].to_s.truncate(500),
        flags: Array(data["flags"]).first(10),
        ai_analysis: data["detailed_analysis"] || {}
      }
    end

    def validate_level(level)
      valid = %w[safe low medium high critical]
      valid.include?(level.to_s) ? level.to_sym : determine_level_from_score(@scan.risk_score)
    end

    def determine_level_from_score(score)
      case score
      when 0..20 then :safe
      when 21..40 then :low
      when 41..60 then :medium
      when 61..80 then :high
      else :critical
      end
    end

    def fallback_analysis
      Analysis::RiskCalculatorService.new(@token).calculate
    end
  end
end
