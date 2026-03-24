class SniperAlertJob < ApplicationJob
  queue_as :default

  def perform(token_id)
    token = Token.find(token_id)

    # Quick data fetch for the alert
    begin
      Tokens::DataFetchService.new(token).fetch!
      result = Analysis::RiskCalculatorService.new(token).calculate
      token.scans.create!(
        risk_score: result[:risk_score], risk_level: result[:risk_level],
        ai_summary: result[:summary], flags: result[:flags],
        scan_type: :auto, status: :completed, completed_at: Time.current
      )
    rescue => e
      Rails.logger.warn "[SniperAlert] Data fetch failed for #{token.mint_address}: #{e.message}"
    end

    # Send to all Pro users with Telegram linked
    bot = TgBot::BotService.new
    pro_users = User.where(tier: :pro).where.not(telegram_chat_id: nil)

    pro_users.find_each do |user|
      bot.send_message(user.telegram_chat_id, format_sniper_alert(token))
    end

    Rails.logger.info "[SniperAlert] Sent alert for #{token.name || token.mint_address} to #{pro_users.count} Pro users"
  end

  private

  def format_sniper_alert(token)
    age_seconds = token.created_on_chain_at ? (Time.current - token.created_on_chain_at).to_i : nil
    age_text = if age_seconds && age_seconds < 60
      "#{age_seconds}s ago"
    elsif age_seconds && age_seconds < 3600
      "#{age_seconds / 60}m ago"
    else
      "just now"
    end

    risk_emoji = case token.risk_level
    when "safe" then "🟢" when "low" then "🟡" when "medium" then "🟠"
    when "high" then "🔴" when "critical" then "🚨" else "⚪" end

    liq = token.liquidity_usd ? "$#{human_number(token.liquidity_usd)}" : "?"
    mcap = token.market_cap_usd ? "$#{human_number(token.market_cap_usd)}" : "?"

    <<~MSG
      ⚡⚡ <b>SNIPER ALERT — NEW TOKEN</b> ⚡⚡

      #{risk_emoji} <b>#{token.name || 'Unknown'}</b> (#{token.symbol || '?'})
      🕐 Launched: #{age_text}

      💰 Liquidity: #{liq}
      📊 Market Cap: #{mcap}
      🛡 Risk: #{token.risk_score || '?'}/100 — #{token.risk_level&.upcase || '?'}

      ✅ Mint Auth: #{token.mint_authority_revoked? ? 'Revoked' : '❌ ACTIVE'}
      ✅ Freeze: #{token.freeze_authority_revoked? ? 'Revoked' : '❌ ACTIVE'}
      ✅ LP Lock: #{token.lp_locked? ? 'Locked' : '❌ UNLOCKED'}

      /scan #{token.mint_address}
    MSG
  end

  def human_number(n)
    return "0" unless n
    if n >= 1_000_000_000 then "#{(n / 1_000_000_000.0).round(1)}B"
    elsif n >= 1_000_000 then "#{(n / 1_000_000.0).round(1)}M"
    elsif n >= 1_000 then "#{(n / 1_000.0).round(1)}K"
    else n.round(2).to_s end
  end
end
