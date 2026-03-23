class TokensController < ApplicationController
  before_action :authenticate_user!, only: [ :scan, :vote ]
  before_action :set_token

  def show
    @scans = @token.scans.completed_scans.recent.limit(10)
    @latest_scan = @scans.first
  end

  def scan
    unless current_user.can_scan?
      redirect_to token_path(@token.mint_address), alert: "Daily scan limit reached. Upgrade to Pro for unlimited scans."
      return
    end

    current_user.increment_scan_count!
    scan = @token.scans.create!(
      user: current_user,
      risk_score: 0,
      risk_level: :safe,
      scan_type: :manual,
      status: :pending
    )
    AiAnalysisJob.perform_later(scan.id)
    redirect_to token_path(@token.mint_address), notice: "Scan initiated. Results will appear shortly."
  end

  def vote
    vote_value = params[:vote]&.to_sym
    unless [ :trust, :distrust ].include?(vote_value)
      redirect_to token_path(@token.mint_address), alert: "Invalid vote."
      return
    end

    trust_vote = current_user.trust_votes.find_or_initialize_by(token: @token)
    trust_vote.vote = vote_value
    trust_vote.save!
    redirect_to token_path(@token.mint_address), notice: "Vote recorded."
  end

  private

  def set_token
    @token = Token.find_by!(mint_address: params[:mint_address])
  end
end
