class WatchlistItemsController < ApplicationController
  before_action :authenticate_user!

  def index
    @watchlist_items = current_user.watchlist_items.includes(:token).order(created_at: :desc)
  end

  def create
    token = Token.find(params[:token_id])
    @watchlist_item = current_user.watchlist_items.build(token: token)

    if @watchlist_item.save
      respond_to do |format|
        format.html { redirect_back fallback_location: feed_path, notice: "Added to watchlist." }
        format.turbo_stream
      end
    else
      redirect_back fallback_location: feed_path, alert: @watchlist_item.errors.full_messages.join(", ")
    end
  end

  def destroy
    @watchlist_item = current_user.watchlist_items.find(params[:id])
    @token = @watchlist_item.token
    @watchlist_item.destroy!

    respond_to do |format|
      format.html { redirect_back fallback_location: watchlist_items_path, notice: "Removed from watchlist." }
      format.turbo_stream
    end
  end
end
