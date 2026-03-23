class AlertsController < ApplicationController
  before_action :authenticate_user!

  def index
    @alerts = current_user.alerts.includes(:token).recent
  end

  def mark_read
    alert = current_user.alerts.find(params[:id])
    alert.mark_read!
    redirect_back fallback_location: alerts_path
  end

  def mark_all_read
    current_user.alerts.unread.update_all(read_at: Time.current)
    redirect_to alerts_path, notice: "All alerts marked as read."
  end
end
