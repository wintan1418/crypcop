require "telegram/bot"
require "net/http"
require "json"

module TgBot
  class BotService
    def initialize
      @token = Rails.application.credentials.dig(:telegram, :bot_token) || ENV["TELEGRAM_BOT_TOKEN"]
    end

    def send_message(chat_id, text, parse_mode: "HTML")
      return unless @token.present?
      uri = URI("https://api.telegram.org/bot#{@token}/sendMessage")
      Net::HTTP.post_form(uri, {
        chat_id: chat_id,
        text: text,
        parse_mode: parse_mode,
        disable_web_page_preview: true
      })
    rescue => e
      Rails.logger.error "[Telegram] Failed to send: #{e.message}"
    end

    def broadcast_new_token(token)
      return unless @token.present?
      users = User.where.not(telegram_chat_id: nil).where(tier: :pro)
      message = format_new_token_alert(token)
      users.find_each { |u| send_message(u.telegram_chat_id, message) }
    end

    def send_risk_alert(user, alert)
      return unless @token.present? && user.telegram_chat_id.present?
      send_message(user.telegram_chat_id, format_risk_alert(alert))
    end

    def send_wallet_alert(user, wallet, transaction)
      return unless @token.present? && user.telegram_chat_id.present?
      send_message(user.telegram_chat_id, format_wallet_alert(wallet, transaction))
    end

    def handle_command(message)
      chat_id = message.chat.id
      text = message.text.to_s.strip

      case text
      when "/start"
        handle_start(chat_id)
      when /^\/scan\s+/
        handle_scan(chat_id, text.sub("/scan", "").strip)
      when "/portfolio"
        handle_portfolio(chat_id)
      when "/alerts"
        send_message(chat_id, "🔔 Alerts are active.\n• New token sniper alerts (Pro)\n• Risk change alerts\n• Whale wallet activity (Pro)")
      when "/help"
        handle_help(chat_id)
      when /^\/link\s+/
        handle_link(chat_id, text.sub("/link", "").strip, message)
      else
        send_message(chat_id, "Unknown command. Type /help for available commands.")
      end
    rescue => e
      Rails.logger.error "[TgBot] Command error: #{e.message}"
      send_message(chat_id, "Something went wrong. Try again.") rescue nil
    end

    private

    def handle_start(chat_id)
      send_message(chat_id, "🛡 <b>Welcome to CrypCop Bot!</b>\n\nI scan Solana tokens for rug pulls.\n\n<b>Commands:</b>\n/scan &lt;address&gt; — Scan any token\n/link &lt;code&gt; — Link your account\n/portfolio — Check portfolio risk\n/help — All commands")
    end

    def handle_help(chat_id)
      send_message(chat_id, "🛡 <b>CrypCop Bot</b>\n\n/scan &lt;address&gt; — Instant risk scan\n/link &lt;code&gt; — Link account\n/portfolio — Portfolio risk\n/alerts — Alert status\n/help — This message\n\n<b>Pro:</b> ⚡ Sniper alerts, 🐋 Whale tracking, 📊 Unlimited scans")
    end

    def handle_scan(chat_id, address)
      unless address.match?(/\A[1-9A-HJ-NP-Za-km-z]{32,44}\z/)
        send_message(chat_id, "❌ Invalid address. Usage: /scan &lt;solana_address&gt;")
        return
      end

      send_message(chat_id, "🔍 Scanning #{address[0..8]}...")

      token = Token.find_by(mint_address: address)
      unless token
        token = Token.create!(mint_address: address, created_on_chain_at: Time.current)
        Tokens::DataFetchService.new(token).fetch!
        result = Analysis::RiskCalculatorService.new(token).calculate
        token.scans.create!(
          risk_score: result[:risk_score], risk_level: result[:risk_level],
          ai_summary: result[:summary], flags: result[:flags],
          scan_type: :manual, status: :completed, completed_at: Time.current
        )
      end

      send_message(chat_id, format_token_report(token))
    rescue => e
      send_message(chat_id, "❌ Scan failed: #{e.message}")
    end

    def handle_portfolio(chat_id)
      user = User.find_by(telegram_chat_id: chat_id.to_s)
      unless user
        send_message(chat_id, "❌ Not linked. Use /link &lt;code&gt; from crypcop.com/dashboard")
        return
      end

      holdings = user.portfolio_holdings.by_risk.limit(10)
      if holdings.empty?
        send_message(chat_id, "📊 No portfolio. Add your wallet at crypcop.com/portfolio")
        return
      end

      msg = "📊 <b>Portfolio Risk</b>\n\n"
      holdings.each do |h|
        emoji = h.risk_score.to_i > 60 ? "🔴" : h.risk_score.to_i > 30 ? "🟡" : "🟢"
        msg += "#{emoji} #{h.token_name || h.token_symbol || '?'} — #{h.risk_score}/100\n"
      end
      send_message(chat_id, msg)
    end

    def handle_link(chat_id, code, message)
      user = User.find_by(telegram_link_token: code)
      unless user
        send_message(chat_id, "❌ Invalid code. Get yours at crypcop.com/dashboard")
        return
      end

      user.update!(
        telegram_chat_id: chat_id.to_s,
        telegram_username: message.from&.username,
        telegram_linked_at: Time.current,
        telegram_link_token: nil
      )
      send_message(chat_id, "✅ Linked! #{user.pro? ? '⭐ Pro active' : '💡 Upgrade for sniper alerts'}")
    end

    def format_token_report(token)
      emoji = case token.risk_level
      when "safe" then "🟢" when "low" then "🟡" when "medium" then "🟠"
      when "high" then "🔴" when "critical" then "🚨" else "⚪" end

      scan = token.scans.completed_scans.recent.first

      msg = "#{emoji} <b>#{token.name || 'Unknown'}</b> (#{token.symbol || '?'})\n\n"
      msg += "<b>Risk:</b> #{token.risk_score || '?'}/100 — #{token.risk_level&.upcase}\n"
      msg += "<b>Price:</b> $#{token.latest_price_usd || '?'}\n"
      msg += "<b>MCap:</b> $#{nh(token.market_cap_usd)}\n"
      msg += "<b>Liq:</b> $#{nh(token.liquidity_usd)}\n"
      msg += "<b>Holders:</b> #{token.holder_count || '?'}\n\n"
      msg += "Mint Auth: #{token.mint_authority_revoked? ? '✅' : '❌'}  "
      msg += "Freeze: #{token.freeze_authority_revoked? ? '✅' : '❌'}  "
      msg += "LP Lock: #{token.lp_locked? ? '✅' : '❌'}\n"

      flags = scan&.flags || []
      if flags.any?
        msg += "\n🚩 <b>Flags:</b>\n"
        flags.first(5).each { |f| msg += "• #{f}\n" }
      end

      msg += "\n#{scan&.ai_summary}" if scan&.ai_summary.present?
      msg
    end

    def format_new_token_alert(token)
      "⚡ <b>NEW TOKEN</b>\n#{token.name || '?'} (#{token.symbol || '?'})\nRisk: #{token.risk_score || '?'}/100\nLiq: $#{nh(token.liquidity_usd)}\n\n/scan #{token.mint_address}"
    end

    def format_risk_alert(alert)
      "#{alert.risk_increase? ? '🔴' : '🟢'} <b>#{alert.title}</b>\n#{alert.message}\n\n/scan #{alert.token.mint_address}"
    end

    def format_wallet_alert(wallet, tx)
      "#{tx.buy? ? '💰' : '💸'} <b>#{wallet.label || wallet.wallet_address[0..8]}</b>\n#{tx.tx_type.upcase}: #{tx.token_symbol || '?'}\nValue: $#{nh(tx.value_usd)}\n\n/scan #{tx.token_mint_address}"
    end

    def nh(n)
      return "?" unless n
      if n >= 1_000_000_000 then "#{(n / 1_000_000_000.0).round(1)}B"
      elsif n >= 1_000_000 then "#{(n / 1_000_000.0).round(1)}M"
      elsif n >= 1_000 then "#{(n / 1_000.0).round(1)}K"
      else n.round(2).to_s end
    end
  end
end
