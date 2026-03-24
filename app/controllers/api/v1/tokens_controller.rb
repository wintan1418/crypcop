module Api
  module V1
    class TokensController < BaseController
      def scan
        address = params[:address]&.strip
        unless address&.match?(/\A[1-9A-HJ-NP-Za-km-z]{32,44}\z/)
          render json: { error: "Invalid Solana address" }, status: :bad_request
          return
        end

        token = Token.find_by(mint_address: address)
        unless token
          token = Token.create!(mint_address: address, created_on_chain_at: Time.current)
          begin
            Tokens::DataFetchService.new(token).fetch!
            result = Analysis::RiskCalculatorService.new(token).calculate
            token.scans.create!(
              risk_score: result[:risk_score], risk_level: result[:risk_level],
              ai_summary: result[:summary], flags: result[:flags],
              scan_type: :manual, status: :completed, completed_at: Time.current
            )
          rescue => e
            render json: { error: "Scan failed: #{e.message}" }, status: :service_unavailable
            return
          end
        end

        scan = token.scans.completed_scans.recent.first
        render json: {
          token: {
            mint_address: token.mint_address,
            name: token.name,
            symbol: token.symbol,
            price_usd: token.latest_price_usd,
            market_cap_usd: token.market_cap_usd,
            liquidity_usd: token.liquidity_usd,
            holder_count: token.holder_count,
            top_10_holder_pct: token.top_10_holder_pct,
            mint_authority_revoked: token.mint_authority_revoked,
            freeze_authority_revoked: token.freeze_authority_revoked,
            lp_locked: token.lp_locked,
            created_on_chain_at: token.created_on_chain_at
          },
          risk: {
            score: token.risk_score,
            level: token.risk_level,
            summary: scan&.ai_summary,
            flags: scan&.flags || [],
            scanned_at: token.last_scanned_at
          },
          verified: token.verified_tokens.active_badges.any?,
          api: {
            calls_remaining: @api_key.calls_remaining
          }
        }
      end

      def show
        token = Token.find_by(mint_address: params[:address])
        unless token
          render json: { error: "Token not found" }, status: :not_found
          return
        end

        render json: {
          mint_address: token.mint_address,
          name: token.name,
          symbol: token.symbol,
          risk_score: token.risk_score,
          risk_level: token.risk_level,
          price_usd: token.latest_price_usd,
          market_cap_usd: token.market_cap_usd,
          liquidity_usd: token.liquidity_usd,
          last_scanned_at: token.last_scanned_at
        }
      end
    end
  end
end
