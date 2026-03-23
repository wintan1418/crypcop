class TokenPriceUpdateJob < ApplicationJob
  queue_as :token_scan

  def perform
    Tokens::PriceUpdateService.new.update!
  end
end
