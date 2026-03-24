class VerifiedTokensController < ApplicationController
  def index
    @verified_tokens = VerifiedToken.active_badges.includes(:token).order(verified_at: :desc)
  end

  def new
    @verified_token = VerifiedToken.new
  end

  def create
    token = Token.find_by(mint_address: params.dig(:verified_token, :mint_address))
    unless token
      redirect_to new_verified_token_path, alert: "Token not found. Search for it first to add it to our database."
      return
    end

    @verified_token = VerifiedToken.new(verified_token_params)
    @verified_token.token = token
    @verified_token.status = :pending
    @verified_token.expires_at = 1.year.from_now

    if @verified_token.save
      redirect_to verified_tokens_path, notice: "Verification request submitted! We'll review it within 24 hours. Payment: $#{@verified_token.price}"
    else
      render :new
    end
  end

  private

  def verified_token_params
    params.require(:verified_token).permit(:badge_type, :contact_email, :project_url, :project_name, :description)
  end
end
