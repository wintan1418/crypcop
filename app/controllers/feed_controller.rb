class FeedController < ApplicationController
  include Pagy::Method

  def index
    tokens = Token.scanned.recent
    tokens = tokens.by_risk(params[:risk]) if params[:risk].present?
    @pagy, @tokens = pagy(tokens, limit: 25)
  end
end
