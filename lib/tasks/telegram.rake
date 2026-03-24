require "telegram/bot"

namespace :telegram do
  desc "Start Telegram bot in polling mode (for local development)"
  task poll: :environment do
    token = ENV["TELEGRAM_BOT_TOKEN"]
    abort "Set TELEGRAM_BOT_TOKEN env var" unless token.present?

    # Remove any webhook so polling works
    require "net/http"
    uri = URI("https://api.telegram.org/bot#{token}/deleteWebhook")
    Net::HTTP.get(uri)

    puts "CrypCop Telegram Bot started (polling mode)..."
    puts "Send /start to your bot in Telegram"

    bot_service = TgBot::BotService.new

    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        puts "[Telegram] Received: #{message.text} from #{message.from&.username}"
        bot_service.handle_command(message)
      rescue => e
        puts "[Telegram] Error: #{e.message}"
      end
    end
  end
end
