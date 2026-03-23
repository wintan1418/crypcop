module Telegram
  class BotService
    def initialize
      @token = Rails.application.credentials.dig(:telegram, :bot_token) || ENV["TELEGRAM_BOT_TOKEN"]
      @bot = ::Telegram::Bot::Client.new(@token) if @token.present?
    end

    # Send a message to a specific chat
    def send_message(chat_id, text, parse_mode: "HTML")
      return unless @bot
      @bot.api.send_message(
        chat_id: chat_id,
        text: text,
        parse_mode: parse_mode,
        disable_web_page_preview: true
      )
    rescue => e
      Rails.logger.error "[Telegram] Failed to send message: #{e.message}"
    end

    # Send new token alert to all subscribers
    def broadcast_new_token(token)
      return unless @bot
      users = User.where.not(telegram_chat_id: nil).where(tier: :pro)
      return if users.empty?

      message = format_new_token_alert(token)
      users.find_each do |user|
        send_message(user.telegram_chat_id, message)
      end
    end

    # Send risk change alert
    def send_risk_alert(user, alert)
      return unless @bot && user.telegram_chat_id.present?
      message = format_risk_alert(alert)
      send_message(user.telegram_chat_id, message)
    end

    # Send wallet activity alert
    def send_wallet_alert(user, wallet, transaction)
      return unless @bot && user.telegram_chat_id.present?
      message = format_wallet_alert(wallet, transaction)
      send_message(user.telegram_chat_id, message)
    end

    # Handle incoming bot commands
    def handle_command(message)
      chat_id = message.chat.id
      text = message.text.to_s.strip

      case text
      when "/start"
        handle_start(chat_id, message)
      when /^\/scan\s+/
        handle_scan(chat_id, text.sub("/scan", "").strip)
      when "/portfolio"
        handle_portfolio(chat_id)
      when "/alerts"
        handle_alerts_toggle(chat_id)
      when "/help"
        handle_help(chat_id)
      when /^\/link\s+/
        handle_link(chat_id, text.sub("/link", "").strip, message)
      else
        send_message(chat_id, "Unknown command. Type /help for available commands.")
      end
    end

    private

    def handle_start(chat_id, message)
      send_message(chat_id, <<~MSG)
        🛡 <b>Welcome to CrypCop Bot!</b>

        I scan Solana tokens for rug pulls and scams.

        <b>Commands:</b>
        /scan &lt;token_address&gt; — Scan any Solana token
        /link &lt;code&gt; — Link your CrypCop account
        /portfolio — Check your portfolio risk
        /help — Show all commands

        🔗 Get your link code at crypcop.com/dashboard
      MSG
    end

    def handle_scan(chat_id, address)
      unless address.match?(/\A[1-9A-HJ-NP-Za-km-z]{32,44}\z/)
        send_message(chat_id, "❌ Invalid Solana address. Usage: /scan <token_address>")
        return
      end

      send_message(chat_id, "🔍 Scanning #{address[0..8]}... please wait")

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
        send_message(chat_id, "❌ Account not linked. Use /link <code> to connect your CrypCop account.")
        return
      end

      holdings = user.portfolio_holdings.by_risk.limit(10)
      if holdings.empty?
        send_message(chat_id, "📊 No portfolio loaded. Add your wallet at crypcop.com/portfolio")
        return
      end

      risky = holdings.risky.count
      message = "📊 <b>Portfolio Risk Summary</b>\n\n"
      message += "⚠️ #{risky} risky tokens detected\n\n" if risky > 0
      holdings.each do |h|
        emoji = h.risk_score.to_i > 60 ? "🔴" : h.risk_score.to_i > 30 ? "🟡" : "🟢"
        message += "#{emoji} #{h.token_name || h.token_symbol || 'Unknown'} — #{h.risk_score}/100\n"
      end
      send_message(chat_id, message)
    end

    def handle_link(chat_id, code, message)
      user = User.find_by(telegram_link_token: code)
      unless user
        send_message(chat_id, "❌ Invalid link code. Get yours at crypcop.com/dashboard")
        return
      end

      user.update!(
        telegram_chat_id: chat_id.to_s,
        telegram_username: message.from&.username,
        telegram_linked_at: Time.current,
        telegram_link_token: nil
      )
      send_message(chat_id, "✅ Account linked! You'll now receive alerts here.\n\n#{user.pro? ? '⭐ Pro features active' : '💡 Upgrade to Pro for sniper alerts'}")
    end

    def handle_alerts_toggle(chat_id)
      send_message(chat_id, "🔔 Alerts are active. You'll receive:\n• New token sniper alerts (Pro)\n• Risk change alerts for watchlist\n• Whale wallet activity (Pro)")
    end

    def handle_help(chat_id)
      send_message(chat_id, <<~MSG)
        🛡 <b>CrypCop Bot Commands</b>

        /scan &lt;address&gt; — Instant token risk scan
        /link &lt;code&gt; — Link your CrypCop account
        /portfolio — View portfolio risk summary
        /alerts — Check alert status
        /help — This message

        <b>Pro Features:</b>
        ⚡ Sniper alerts for new tokens
        🐋 Whale wallet tracking alerts
        📊 Unlimited scans
      MSG
    end

    def format_token_report(token)
      risk_emoji = case token.risk_level
      when "safe" then "🟢"
      when "low" then "🟡"
      when "medium" then "🟠"
      when "high" then "🔴"
      when "critical" then "🚨"
      else "⚪"
      end

      scan = token.scans.completed_scans.recent.first
      flags = scan&.flags || []

      msg = <<~MSG
        #{risk_emoji} <b>#{token.name || 'Unknown'}</b> (#{token.symbol || '?'})

        <b>Risk Score:</b> #{token.risk_score || 'N/A'}/100 — #{token.risk_level&.upcase || 'UNKNOWN'}
        <b>Price:</b> $#{token.latest_price_usd || 'N/A'}
        <b>Market Cap:</b> $#{token.market_cap_usd ? number_human(token.market_cap_usd) : 'N/A'}
        <b>Liquidity:</b> $#{token.liquidity_usd ? number_human(token.liquidity_usd) : 'N/A'}
        <b>Holders:</b> #{token.holder_count || 'N/A'}

        <b>Mint Authority:</b> #{token.mint_authority_revoked? ? '✅ Revoked' : '❌ Active'}
        <b>Freeze Authority:</b> #{token.freeze_authority_revoked? ? '✅ Revoked' : '❌ Active'}
        <b>LP Locked:</b> #{token.lp_locked? ? '✅ Yes' : '❌ No'}
      MSG

      if flags.any?
        msg += "\n<b>🚩 Red Flags:</b>\n"
        flags.first(5).each { |f| msg += "• #{f}\n" }
      end

      if scan&.ai_summary.present?
        msg += "\n<b>AI Summary:</b> #{scan.ai_summary}"
      end

      msg
    end

    def format_new_token_alert(token)
      <<~MSG
        ⚡ <b>NEW TOKEN DETECTED</b>

        <b>#{token.name || 'Unknown'}</b> (#{token.symbol || '?'})
        Risk: #{token.risk_score || '?'}/100
        Liquidity: $#{token.liquidity_usd ? number_human(token.liquidity_usd) : '?'}

        /scan #{token.mint_address}
      MSG
    end

    def format_risk_alert(alert)
      emoji = alert.risk_increase? ? "🔴" : "🟢"
      <<~MSG
        #{emoji} <b>#{alert.title}</b>

        #{alert.message}

        /scan #{alert.token.mint_address}
      MSG
    end

    def format_wallet_alert(wallet, tx)
      emoji = tx.buy? ? "💰" : "💸"
      <<~MSG
        #{emoji} <b>Whale Activity: #{wallet.label || wallet.wallet_address[0..8]}</b>

        #{tx.tx_type.upcase}: #{tx.token_symbol || 'Unknown'}
        Amount: $#{tx.value_usd ? number_human(tx.value_usd) : '?'}

        /scan #{tx.token_mint_address}
      MSG
    end

    def number_human(n)
      return "0" unless n
      if n >= 1_000_000_000 then "#{(n / 1_000_000_000.0).round(1)}B"
      elsif n >= 1_000_000 then "#{(n / 1_000_000.0).round(1)}M"
      elsif n >= 1_000 then "#{(n / 1_000.0).round(1)}K"
      else n.round(2).to_s
      end
    end
  end
end
