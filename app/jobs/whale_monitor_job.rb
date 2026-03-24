class WhaleMonitorJob < ApplicationJob
  queue_as :default

  def perform
    wallets = TrackedWallet.where(is_smart_money: true).or(TrackedWallet.where(is_whale: true))
    return if wallets.empty?

    bot = TgBot::BotService.new
    pro_users = User.where(tier: :pro).where.not(telegram_chat_id: nil)

    wallets.find_each do |wallet|
      begin
        service = Wallets::TrackerService.new(wallet)
        new_txs = service.fetch_recent_transactions!

        new_txs.each do |tx|
          next unless tx.buy? || tx.sell?

          # Broadcast to all Pro users on Telegram
          message = format_whale_signal(wallet, tx)
          pro_users.find_each do |user|
            bot.send_message(user.telegram_chat_id, message)
          end

          # Also notify the specific wallet owner
          if wallet.user.telegram_chat_id.present?
            if (tx.buy? && wallet.notify_on_buy?) || (tx.sell? && wallet.notify_on_sell?)
              bot.send_wallet_alert(wallet.user, wallet, tx)
            end
          end
        end
      rescue => e
        Rails.logger.warn "[WhaleMonitor] Error tracking #{wallet.label}: #{e.message}"
      end
    end
  end

  private

  def format_whale_signal(wallet, tx)
    emoji = tx.buy? ? "🐋💰" : "🐋💸"
    action = tx.buy? ? "BOUGHT" : "SOLD"

    token_info = if tx.token
      "#{tx.token.name || tx.token_symbol} (#{tx.token.symbol || '?'})"
    else
      tx.token_symbol || "Unknown Token"
    end

    value = tx.value_usd ? "$#{human_number(tx.value_usd)}" : "Unknown value"

    risk_line = if tx.token&.risk_score
      risk_emoji = tx.token.risk_score > 60 ? "🔴" : tx.token.risk_score > 30 ? "🟡" : "🟢"
      "\n#{risk_emoji} Risk: #{tx.token.risk_score}/100"
    else
      ""
    end

    <<~MSG
      #{emoji} <b>WHALE SIGNAL</b>

      <b>#{wallet.label || wallet.wallet_address[0..12]}</b> #{action}:
      🪙 #{token_info}
      💵 Value: #{value}#{risk_line}

      #{tx.token_mint_address ? "/scan #{tx.token_mint_address}" : ""}
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
