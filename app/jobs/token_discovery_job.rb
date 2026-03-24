class TokenDiscoveryJob < ApplicationJob
  queue_as :token_discovery

  def perform
    service = Tokens::DiscoveryService.new
    new_tokens = service.discover!

    new_tokens.each do |token|
      BroadcastTokenJob.perform_later(token.id)
      SniperAlertJob.perform_later(token.id)
    end
  end
end
