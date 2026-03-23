class AiAnalysisJob < ApplicationJob
  queue_as :ai_analysis
  retry_on Solana::Client::ApiError, wait: 10.seconds, attempts: 2

  def perform(scan_id)
    scan = Scan.find(scan_id)
    token = scan.token
    old_risk_score = token.risk_score || 0

    scan.update!(status: :processing)

    # Use Claude AI if API key is set, otherwise deterministic scorer
    result = Analysis::AiAnalysisService.new(token, scan).analyze!

    scan.update!(
      risk_score: result[:risk_score],
      risk_level: result[:risk_level],
      ai_summary: result[:summary],
      ai_analysis: result[:ai_analysis] || {},
      flags: result[:flags],
      holder_snapshot: { top_10_pct: token.top_10_holder_pct, count: token.holder_count },
      liquidity_snapshot: { usd: token.liquidity_usd, lp_locked: token.lp_locked },
      status: :completed,
      completed_at: Time.current
    )

    # Broadcast updated token to feed
    BroadcastTokenJob.perform_later(token.id)

    # Dispatch alerts if risk changed significantly
    new_risk_score = result[:risk_score]
    if (new_risk_score - old_risk_score).abs >= 10
      AlertDispatchJob.perform_later(token.id, old_risk_score, new_risk_score)
    end
  rescue => e
    scan.update!(status: :failed, error_message: e.message) if scan&.persisted?
    raise
  end
end
