class SearchController < ApplicationController
  include Pagy::Method

  def index
    if params[:q].present?
      @query = params[:q].strip
      if solana_address?(@query)
        @token = Token.find_by(mint_address: @query)
        if @token
          redirect_to token_path(@token.mint_address)
          return
        else
          # Create token on-demand and trigger scan pipeline
          @token = Token.create!(mint_address: @query, created_on_chain_at: Time.current)
          TokenDataFetchJob.perform_later(@token.id)
          redirect_to token_path(@token.mint_address), notice: "Token found! Scanning now..."
          return
        end
      end
      @pagy, @tokens = pagy(Token.search_by_name_or_symbol(@query), limit: 20)
    else
      @tokens = []
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    @token = Token.find_by(mint_address: @query)
    redirect_to token_path(@token.mint_address) if @token
  end

  private

  def solana_address?(str)
    str.match?(/\A[1-9A-HJ-NP-Za-km-z]{32,44}\z/)
  end
end
