class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @recent_scans = current_user.scans.includes(:token).recent.limit(10)
    @watchlist_items = current_user.watchlist_items.includes(:token).limit(5)
    @recent_alerts = current_user.alerts.includes(:token).unread.recent.limit(5)
    @scans_remaining = current_user.scans_remaining
  end
end
