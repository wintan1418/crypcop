class BroadcastTokenJob < ApplicationJob
  queue_as :default

  def perform(token_id)
    token = Token.find(token_id)

    Turbo::StreamsChannel.broadcast_prepend_to(
      "token_feed",
      target: "token-feed",
      partial: "tokens/card",
      locals: { token: token }
    )
  end
end
