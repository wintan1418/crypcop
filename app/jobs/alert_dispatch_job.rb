class AlertDispatchJob < ApplicationJob
  queue_as :alerts

  def perform(token_id, old_risk_score, new_risk_score)
    token = Token.find(token_id)
    watchlist_items = token.watchlist_items.where(notify_on_risk_change: true).includes(:user)

    return if watchlist_items.empty?

    alert_type = new_risk_score > old_risk_score ? :risk_increase : :risk_decrease
    direction = new_risk_score > old_risk_score ? "increased" : "decreased"

    watchlist_items.each do |item|
      alert = item.user.alerts.create!(
        token: token,
        alert_type: alert_type,
        title: "#{token.name || token.symbol} risk #{direction}",
        message: "Risk score changed from #{old_risk_score} to #{new_risk_score} for #{token.name || token.mint_address}."
      )

      # Send email notification
      AlertMailer.risk_change(alert).deliver_later

      # Broadcast real-time toast to user
      Turbo::StreamsChannel.broadcast_append_to(
        "alerts:#{item.user.id}",
        target: "flash-messages",
        partial: "alerts/toast",
        locals: { alert: alert }
      )
    end
  end
end
