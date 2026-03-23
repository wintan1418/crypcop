class TokenDataFetchJob < ApplicationJob
  queue_as :token_scan
  retry_on Solana::Client::ApiError, wait: 5.seconds, attempts: 3
  retry_on Solana::Client::RateLimitError, wait: 30.seconds, attempts: 2

  def perform(token_id)
    token = Token.find(token_id)
    service = Tokens::DataFetchService.new(token)
    service.fetch!

    # After data is fetched, run AI analysis
    scan = token.scans.create!(
      risk_score: 0,
      risk_level: :safe,
      scan_type: :auto,
      status: :pending
    )
    AiAnalysisJob.perform_later(scan.id)
  end
end
