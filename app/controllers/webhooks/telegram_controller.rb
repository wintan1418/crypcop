module Webhooks
  class TelegramController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      update = Telegram::Bot::Types::Update.new(JSON.parse(request.body.read))
      if update.message
        Telegram::BotService.new.handle_command(update.message)
      end
      head :ok
    rescue => e
      Rails.logger.error "[TelegramWebhook] Error: #{e.message}"
      head :ok
    end
  end
end
